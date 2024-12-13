from collections import OrderedDict
import json
import logging
import datetime
import os
from flask import Flask, request, jsonify
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from fedex import FedExAPI
import datetime

app = Flask(__name__)

#add JWT configuration
app.config["JWT_SECRET_KEY"] = os.environ.get("JWT_SECRET_KEY")
app.config["JSON_SORT_KEYS"] = False
jwt = JWTManager(app)
fedex = FedExAPI()

@app.route("/api/login", methods=["POST"])
def login():
    username = request.json.get("client_id", None)
    password = request.json.get("client_secret", None)
    if username != os.environ.get("USERNAME") or password != os.environ.get("PASSWORD"):
        return jsonify({"msg": "Bad username or password"}), 401
        
    access_token = create_access_token(identity=username)
    return jsonify({"access_token": access_token}), 200

@app.route("/api", methods=["GET"])
@jwt_required()
def get_api_documentation():
    app.logger.debug("Fetching API documentation")
    
    documentation = {
        "version": "1.0.0",
        "endpoints": {
            "fedex": {
                "ship": {
                    "method": "POST",
                    "endpoint": "/api/fedex/ship",
                    "description": "Create a FedEx shipment",
                    "request": {
                        "content_type": "application/json",
                        "schema": {
                            "origin": {
                                "type": "string",
                                "description": "Valid shipping origin location",
                                "required": True
                            },
                            "recipients": {
                                "type": "object",
                                "required": True,
                                "properties": {
                                    "contact": {
                                        "personName": "string",
                                        "phoneNumber": "string",
                                        "companyName": "string"
                                    },
                                    "address": {
                                        "streetLines": ["string"],
                                        "city": "string",
                                        "stateOrProvinceCode": "string",
                                        "postalCode": "string",
                                        "countryCode": "string",
                                        "residential": "boolean"
                                    }
                                }
                            }
                        }
                    },
                    "responses": {
                        "200": "Successful shipment creation",
                        "400": "Invalid request", 
                        "500": "Internal server error"
                    }
                }
            }
        }
    }
    
    return jsonify(documentation), 200

@app.route("/api/fedex/ship", methods=["POST"])
@jwt_required()
def fedex_create_shipment():
    try:
        # Validate request body
        payload = request.get_json()
        if not payload:
            return jsonify({"error": "Missing request body"}), 400
        
        # Extract and validate required fields
        origin = payload.get("origin")
        recipients = payload.get("recipients")

        if not origin or not recipients:
            return jsonify({"error": "Missing required fields: origin, recipients"}), 400
        
        if origin not in fedex.VALID_ORIGINS:
            return jsonify({"error": f"Invalid origin. Must be one of: {fedex.VALID_ORIGINS}"}), 400
        
        # Get access token
        access_token = fedex.generate_access_token()
        
        # Generate shipment payload
        shipment_payload = fedex.populate_shipment_payload(
            origin=origin,
            recipient=recipients
        )
        
        # Create shipment with FedEx
        response = fedex.create_shipment(
            access_token=access_token,
            payload=shipment_payload
        )
        
        return response, 200
    
    except Exception as e:
        app.logger.error(f"Error creating shipment: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    import os
    debug_mode = os.getenv('FLASK_DEBUG', 'False').lower() in ['true', '1', 't']
    app.run(debug=debug_mode)