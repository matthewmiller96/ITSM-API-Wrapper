import requests, os, json
from dotenv import load_dotenv
from datetime import datetime

class FEDEX_API:
    
    def generate_access_token(self):
        client_id = os.environ.get("client_id")
        client_secret = os.environ.get("client_secret")
        url = os.environ.get("base_url")+"/oauth/token"

        payload = f"grant_type=client_credentials&client_id={client_id}&client_secret={client_secret}"
        headers = {
            "Content-Type": "application/x-www-form-urlencoded"
        }
        response = requests.post(url=url, data=payload, headers=headers)

        if response.status_code != 200:
            raise requests.HTTPError(f"failed to generate access token: {response.text}")
        else:
            access_token = response.json().get("access_token")
            return access_token

    def base_shipment_payload(self):
        now = datetime.now().strftime("%Y-%m-%d")
        account_number = os.environ.get("account_number")
        return {
            "labelResponseOptions": "LABEL",
            "requestedShipment": {
                "totalDeclaredValue": {
                    "amount": 1000,
                    "currency": "USD"
                },
                "shipper": {

                },
                "recipients": [
                    {

                    }
                ],
                "shipDatestamp": f"{now}",
                "serviceType": "GROUND_HOME_DELIVERY",
                "packagingType": "YOUR_PACKAGING",
                "pickupType": "USE_SCHEDULED_PICKUP",
                "blockInsightVisibility": "false",
                "shippingChargesPayment": {
                    "paymentType": "SENDER"
                },
                "labelSpecification": {
                    "labelFormatType": "COMMON2D",
                    "imageType": "ZPLII",
                    "labelStockType": "STOCK_4X6"
                },
                "requestedPackageLineItems": [
                    {
                        "weight": {
                            "value": 5,
                            "units": "LB"
                        }
                    }
                ]
            },
            "accountNumber": {
                "value": f"{account_number}"
            }
        }
    
    def load_json(self, file_path):
        with open(file_path, "r") as file:
            return json.load(file)

    def populate_shipment_payload(self, origin, recipient):
        shipper_locations = self.load_json("addresses.json")
        shipper = shipper_locations[origin]
        recipient = recipient
        payload = self.base_shipment_payload()
        payload["requestedShipment"]["shipper"], payload["requestedShipment"]["recipients"][0] = shipper, recipient
        return json.dumps(payload, indent=2)
