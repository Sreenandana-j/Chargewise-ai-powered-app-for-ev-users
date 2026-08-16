from datetime import datetime
# Get current date and time
now = datetime.now()
#temporary charger list
chargers = {
    "Home_AC": {
        "type": "AC",
        "power": 7.2,          # kW
        "connector": "Type 2"
    },

    "Public_AC": {
        "type": "AC",
        "power": 11,           # kW
        "connector": "Type 2"
    },

    "Fast_DC": {
        "type": "DC",
        "power": 50,           # kW
        "connector": "CCS2"
    },

    "Rapid_DC": {
        "type": "DC",
        "power": 120,          # kW
        "connector": "CCS2"
    },

    "UltraFast_DC": {
        "type": "DC",
        "power": 240,          # kW
        "connector": "CCS2"
    }
}
#temporary cars set
cars = {
    "Tata_Nexon": {
        "battery_capacity": 45.0,      # kWh
        "range": 489,                  # km
        "dc_charging_power": 60,       # kW
        "ac_charging_power": 7.2       # kW
    },

    "TataPunch": {
        "battery_capacity": 35.0,      # kWh
        "range": 421,                  # km
        "dc_charging_power": 50,       # kW
        "ac_charging_power": 7.2       # kW
    },

    "KiaEV6": {
        "battery_capacity": 77.4,      # kWh
        "range": 708,                  # km
        "dc_charging_power": 240,      # kW
        "ac_charging_power": 11        # kW
    },

    "MGWindsor": {
        "battery_capacity": 38.0,      # kWh
        "range": 331,                  # km
        "dc_charging_power": 45,       # kW
        "ac_charging_power": 7.4       # kW
    }
}

def choose(cars):#the user chooses their car
    car_names = list(cars.keys())

    print("Select a car:\n")

    for i, car in enumerate(car_names, start=1):
        print(f"{i}. {car}")

    choice = int(input("\nEnter your choice: "))

    selected_car_name = car_names[choice - 1]
    selected_car = cars[selected_car_name]

    bc = selected_car["battery_capacity"]
    return bc,selected_car

bc,car=choose(cars)
tb=int(input("target battery"))
cb=int(input('current battery'))
if cb>tb:
    print("target battery must be greater that current battery")
    exit()

def enrq(bc,tb,cb):# energy required
    en=bc*((tb-cb)/100)
    return(en)
en=enrq(bc,tb,cb)
print(f"total energy required : {en}")


# %H = Hour (24-hour clock), %M = Minute, %S = Second
current_time_24 = now.strftime("%H:%M:%S")
hours=int(now.strftime('%H'))
if 16 <= hours < 22:
    er=24# electricity rate (changes with time as well as brand of chargers)
else:
    er=17

def tc(en,er):
    tcv=en*er*1.1
    return(tcv)
total=tc(en,er)#total coxt to charge the battery to the required energy level(battery percent)
print(f"total cost required: {total}")

#calculate the charger power based on the vehicle as well as the chargers
#temporary :using a fixed charger which is meant to be changeable when the map is included
charger = chargers["Rapid_DC"]

if charger["type"] == "AC":
    ch = min(charger["power"], car["ac_charging_power"])
else:
    ch= min(charger["power"], car["dc_charging_power"])

#calculte the time required to charge
def time(ch,en):
    ti=en/ch
    hours = int(ti)
    minutes = int((ti-hours)*60)
    return hours, minutes
hours,minutes=time(ch,en)
print(f"{hours} hours {minutes} minutes")


# battery losss
vrage=car["range"]# taken from the temporary dataset
sb=int(input("starting battery"))
sb = max(0, min(sb, 100))#starting battery
td=int(input("trip distance"))#taken from the map api(total distance)
def end(sb,vrage,td):
    eb=sb-((td/vrage)*100)
    eb = max(0, eb)
    return(eb)
eb=end(sb,vrage,td)#(the ending batteeryy after a trip)
print(eb)


def early(cb,bc,ch,vrage,td):
    loss=(td/vrage)*100
    l=loss+15#the amount of  battery the car must have to comleate this trip successfully
    l=min(l,100)
    if l>cb:
        en=enrq(bc,l,cb)
        hours,minutes=time(ch,en)
        return True,hours,minutes,l
    else:
        return False,0,0,0


charging_needed,hours,minutes,needed=early(cb,bc,ch,vrage,td)
if charging_needed:
    print(f"you need to chage your battery till {needed} or for {hours} hours and {minutes} minutes")
else:
    print('you have adequate battery to compleate the trip')
