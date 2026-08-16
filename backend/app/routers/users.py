"""
Users router – profile management for authenticated users.

Endpoints:
  GET  /user/profile  – fetch the current user's profile
  PUT  /user/profile  – update display name
"""
import logging

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app import models
from app.database import get_db
from app.schemas import UserProfileResponse
from app.utils import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/user", tags=["Users"])


class UpdateProfileRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100, example="Jane Doe")


@router.get(
    "/profile",
    response_model=UserProfileResponse,
    summary="Get current user profile",
)
def get_profile(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """Return the authenticated user's profile, including their trip count."""
    trip_count = (
        db.query(models.Trip).filter(models.Trip.user_id == current_user.id).count()
    )
    return {
        "id": current_user.id,
        "name": current_user.name,
        "email": current_user.email,
        "is_active": current_user.is_active,
        "created_at": current_user.created_at,
        "trip_count": trip_count,
    }


@router.put(
    "/profile",
    response_model=UserProfileResponse,
    summary="Update display name",
)
def update_profile(
    payload: UpdateProfileRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """Update the authenticated user's display name."""
    current_user.name = payload.name
    db.commit()
    db.refresh(current_user)

    trip_count = (
        db.query(models.Trip).filter(models.Trip.user_id == current_user.id).count()
    )
    logger.info("User profile updated: id=%d", current_user.id)

    return {
        "id": current_user.id,
        "name": current_user.name,
        "email": current_user.email,
        "is_active": current_user.is_active,
        "created_at": current_user.created_at,
        "trip_count": trip_count,
    }
