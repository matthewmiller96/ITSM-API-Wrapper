import requests
import os
import json
import logging
from typing import Dict, Any
from dotenv import load_dotenv
from datetime import datetime
from requests.exceptions import HTTPError
from pathlib import Path

class FedExAPI:
    # FedEx api client for handling shiment creation
    # enviroment variables
    client_id: str
    client_secret: str
    base_url: str
    account_number: str
    logger: logging.Logger

    #define valid origin locations
    VALID_ORIGINS = ("Seattle", "Provo")

    def __init__(self) -> None:
        """initialize api client with env variables"""
        
        #Load .env from config directory
        env_path = Path(__file__).parent / "config" / "fedex"/ ".env"
        load_dotenv(dotenv_path=env_path)
        
        #Get environment variables
        self.client_id = os.environ.get("client_id")
        self.client_secret = os.environ.get("client_secret")
        self.base_url = os.environ.get("base_url")
        self.account_number = os.environ.get("account_number")
        
        # verify environment variables are set
        missing_vars = [var for var, val in {
            "client_id": self.client_id, 
            "client_secret": self.client_secret, 
            "base_url": self.base_url, 
            "account_number": self.account_number
        }.items() if not val]
        if missing_vars:
            raise ValueError(f"Missing environment variables: {', '.join(missing_vars)}")
        
        self.logger = logging.getLogger(__name__)
    
    def generate_access_token(self) -> str:
        # create access token for future authorization
        try:
            url = self.base_url+"/oauth/token"
            payload = {
                "grant_type": "client_credentials",
                "client_id": self.client_id,
                "client_secret": self.client_secret
            }
            headers = {
                "Content-Type": "application/x-www-form-urlencoded"
            }

            self.logger.debug("Generating access token")
            
            response = requests.post(
                url=url, 
                data=payload, 
                headers=headers
            )
            
            response.raise_for_status()

            access_token = response.json().get("access_token")
            if not access_token:
                raise ValueError("Failed to generate access token")
            
            return access_token
        
        except (HTTPError, ValueError) as e:
            self.logger.error(f"Failed to generate access token: {str(e)}")
            raise

    def base_shipment_payload(self) -> Dict[str, Any]:
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
                "shipDatestamp": datetime.now().strftime("%Y-%m-%d"),
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
                "value": self.account_number
            }
        }
    
    def load_address_config(self) -> Dict[str, Dict[str, Any]]:
        #Load shipper addresses from json file
        config_path = Path(__file__).parent / "config" / "fedex" / "address.json"
        try:
            with open(config_path) as f:
                address = json.load(f)
            return address
        except FileNotFoundError:
            self.logger.error(f"Address config not found at {config_path}")
            raise
        except json.JSONDecodeError:
            self.logger.error("Invalid JSON in address config")
            raise
    
    def populate_shipment_payload(
            self, 
            origin: VALID_ORIGINS,  # type: ignore
            recipient: Dict[str, Any]
            ) -> Dict[str, Any]:
        #Populate base payload with recipient and shipper addresses
        if not hasattr(self, '_address_config'):
            self._address_config = self.load_address_config()

        if origin not in self._address_config:
            raise ValueError(f"Invalid origin: {origin}")
        
        self.logger.debug("Populating shipment payload")

        payload = self.base_shipment_payload()
        payload["requestedShipment"]["shipper"] = self._address_config[origin]
        payload["requestedShipment"]["recipients"] = [recipient]
        
        return payload

    def create_shipment(
            self, 
            access_token: str, 
            payload: Dict[str, Any]
    ) -> Dict[str, Any]:
        
        if not access_token:
            raise ValueError("Access token required")
        
        url = f"{self.base_url}/ship/v1/shipments"

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {access_token}"
        }

        self.logger.debug("Creating FedEx shipment")
        try:
            response = requests.post(
                url=url,
                json=payload,
                headers=headers,
                timeout=30
            )
            response.raise_for_status()

            self.logger.info("Successfully created FedEx shipment")
            return response.json()
        except requests.exceptions.RequestException as e:
            self.logger.error(f"Failed to create shipment: {str(e)}")
            raise HTTPError(f"Failed to create shipment: {str(e)}")
