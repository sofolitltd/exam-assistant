EMULATOR_ID ?= Pixel_8
EMULATOR_DEVICE_ID ?= emulator-5554
LAN_IP := $(shell ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
REAL_DEVICE_ID ?= $(shell flutter devices --machine 2>/dev/null | python3 -c 'import json,sys; devices=json.load(sys.stdin); print(next((d["id"] for d in devices if str(d.get("targetPlatform", "")).startswith("android") and not d.get("emulator", False)), ""))')
API_LOCAL_EMULATOR_URL ?= http://10.0.2.2:8080
API_PROD_URL ?=

.DEFAULT_GOAL := help
.PHONY: help setup run run-web run-e run-r run-e-l run-e-p run-r-l run-r-p analyze build-web clean

help:
	@echo "Flutter app commands:"
	@echo "  make setup       Install Flutter dependencies"
	@echo "  make run-web     Run on Chrome"
	@echo "  make run-e-l     Run on Android emulator with local Go API"
	@echo "  make run-e-p     Run on Android emulator with production Go API"
	@echo "  make run-r-l     Run on real Android device with local Go API"
	@echo "  make run-r-p     Run on real Android device with production Go API"
	@echo "  make analyze     Run Flutter analysis"
	@echo "  make build-web   Build the web app"
	@echo "Start the Go API separately with make -C ../exam_assistant_api run."

setup:
	flutter pub get

run: run-web

run-web:
	flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080

run-e: run-e-l
run-r: run-r-p

run-e-l:
	flutter emulators --launch "$(EMULATOR_ID)" || true
	flutter run -d "$(EMULATOR_DEVICE_ID)" --dart-define=API_BASE_URL=$(API_LOCAL_EMULATOR_URL)

run-e-p:
	@test -n "$(API_PROD_URL)" || { echo "Set API_PROD_URL to the deployed Go API URL."; exit 1; }
	flutter emulators --launch "$(EMULATOR_ID)" || true
	flutter run -d "$(EMULATOR_DEVICE_ID)" --dart-define=API_BASE_URL=$(API_PROD_URL)

run-r-l:
	@test -n "$(LAN_IP)" || { echo "Wi-Fi IP not found on en0/en1."; exit 1; }
	@test -n "$(REAL_DEVICE_ID)" || { echo "No real Android device found. Connect it and enable USB debugging."; exit 1; }
	@curl --fail --silent --show-error --max-time 2 "http://$(LAN_IP):8080/health" >/dev/null || { echo "Local API is not reachable at http://$(LAN_IP):8080. Set API_ADDR=:8080 in exam_assistant_api/.env and restart the API."; exit 1; }
	flutter run -d "$(REAL_DEVICE_ID)" --dart-define=API_BASE_URL=http://$(LAN_IP):8080

run-r-p:
	@test -n "$(API_PROD_URL)" || { echo "Set API_PROD_URL to the deployed Go API URL."; exit 1; }
	@test -n "$(REAL_DEVICE_ID)" || { echo "No real Android device found. Connect it and enable USB debugging."; exit 1; }
	flutter run -d "$(REAL_DEVICE_ID)" --dart-define=API_BASE_URL=$(API_PROD_URL)

analyze:
	flutter analyze

build-web:
	flutter build web

clean:
	flutter clean
