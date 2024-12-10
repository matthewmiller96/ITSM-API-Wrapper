# API Middleware

## Purpose
I have spent the last year designing complex Jira integrations with external systems using web requests of varying complexity. While each integration has its own challenges and complexities, there exist a limited number of inputs that I actually need from an ITSM system. By consolidating the web requests into a modular framework, I am able to maintain higher levels of control, logging, and validation.

For this project I am running the Flask app on a Raspberry Pi using Ubuntu Server 20.04.

## Prerequisites
- Python 3.8+
- FedEx API credentials (obtain from [FedEx Developer Resource Center](https://www.fedex.com/en-us/developer.html))
- Valid account number

## Installation

1. Clone the repository
2. Run setup script:
```bash
[setup.sh](./setup.sh)

