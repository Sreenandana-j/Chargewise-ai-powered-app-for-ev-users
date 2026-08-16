"""
Authentication router – handles user signup and login.

Endpoints:
  POST /auth/signup  – register a new user
  POST /auth/login   – authenticate and receive a JWT
"""
import logging
from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import models
from app.auth import create_access_token, hash_password, verify_password
from app.config import settings
from app.database import get_db
from app.schemas import MessageResponse, TokenResponse, UserLoginRequest, UserSignupRequest, UserResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post(
    "/signup",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
    responses={
        409: {"description": "Email already registered"},
    },
)
def signup(payload: UserSignupRequest, db: Session = Depends(get_db)) -> models.User:
    """
    Create a new user account.

    - **name**: Full display name (2–100 characters)
    - **email**: Unique email address
    - **password**: Minimum 8 characters, must contain uppercase and a digit
    """
    existing = db.query(models.User).filter(models.User.email == payload.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"An account with email '{payload.email}' already exists.",
        )

    user = models.User(
        name=payload.name,
        email=payload.email,
        password_hash=hash_password(payload.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    logger.info("New user registered: id=%d email=%s", user.id, user.email)
    return user


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Authenticate and get JWT token",
    responses={
        401: {"description": "Invalid credentials"},
    },
)
def login(payload: UserLoginRequest, db: Session = Depends(get_db)) -> dict:
    """
    Authenticate with email and password, and receive a JWT Bearer token.

    Use the returned ``access_token`` in the ``Authorization: Bearer <token>`` header
    for all protected endpoints.
    """
    user = db.query(models.User).filter(models.User.email == payload.email).first()

    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account has been deactivated. Please contact support.",
        )

    expire_delta = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email, "user_id": user.id},
        expires_delta=expire_delta,
    )

    logger.info("User logged in: id=%d email=%s", user.id, user.email)

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "expires_in": int(expire_delta.total_seconds()),
    }
