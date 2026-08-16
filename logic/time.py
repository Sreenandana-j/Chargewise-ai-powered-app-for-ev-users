from datetime import datetime
# Get current date and time
now = datetime.now()
# %H = Hour (24-hour clock), %M = Minute, %S = Second
current_time_24 = now.strftime("%H:%M:%S")
hours=int(now.strftime('%H'))
if 16>hours<9:
    price=24
else:
    price=17
print(price)