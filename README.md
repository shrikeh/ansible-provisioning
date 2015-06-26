# Inviqa Ansible Provisioning

## Prerequisites

You must have a Python > 2.6 (not system Python on Mac OSX) with pip:

```bash
brew install python
```
## Installation
Clone this repo to your local machine:

```bash
git clone https://github.com/inviqa/ansible-provisioning.git
cd ansible-provisioning
```
Create an Ansible inventory file based on the example in inventor.sample
You will need the Provisioning Vault Password from LastPass
```bash
cp ./inventory.sample ~/.inventory
source ./provision.sh  --inventory ~/.inventory
```
