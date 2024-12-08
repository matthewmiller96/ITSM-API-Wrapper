from flask import Flask, request, jsonify
from fedex import FEDEX_API

app = Flask(__name__)
fedex = FEDEX_API()

@app.route("/api", methods=["GET"])
def fedex_endpoints():
    return jsonify({
        "endpoints": {
            "fedex":{
                "ship": {
                    "method": "POST",
                    "endpoint": "/api/fedex/ship"
                },
                "track": {
                    "method": "GET",
                    "endpoint": "/api/fedex/track"
                },
            }
        }
    }), 200

@app.route("/api/fedex/ship", methods=["POST"])
def fedex_create_shipment():
    payload = request.get_json()
    origin = payload["origin"]
    recipient = payload["recipientData"]
    shipment_request = fedex.populate_shipment_payload(origin, recipient)

    return shipment_request


if __name__ == "__main__":
    app.run(debug=True)
