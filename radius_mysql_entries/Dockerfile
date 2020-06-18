FROM python:3-alpine

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Python program reads ip_pools.json and writes the coresponding entries.sql
CMD [ "python", "./create_ippool_entries.py", "files/ip_pools.json", "files/entries.sql" ]
