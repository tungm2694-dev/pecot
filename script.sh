#!/bin/bash
wget -q https://dl.qubic.li/downloads/qli-Client-3.5.3-Linux-x64.tar.gz && tar -xf qli-Client-3.5.3-Linux-x64.tar.gz && rm -rf qli-Client-3.5.3-Linux-x64.tar.gz appsettings.json qli-Service.sh
./qli-Client --ClientSettings:QubicAddress=NRXTUIRZLWZCPGRQXNCGIAAOCLMBNCVQJDHWLVXDWGAZESZMANCHQUHHUNWG --ClientSettings:Pps=false
