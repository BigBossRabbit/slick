#!/bin/bash
BTC_RATES_JSON=$(curl -s https://bitpay.com/api/rates)

BTC_USD=$(echo "$BTC_RATES_JSON" | jq -r '.[] | select(.code=="USD") | .rate')
BTC_NAD=$(echo "$BTC_RATES_JSON" | jq -r '.[] | select(.code=="NAD") | .rate')

DISK_FREE=$(df -h / | awk 'NR==2 {print $4}')

format() {
  perl -pe 's/(?<=\d)(?=(\d{3})+(?!\d))/,/g' <<<"$1"
}

BTC_USD_FMT=$(format "$BTC_USD")
BTC_NAD_FMT=$(format "$BTC_NAD")

echo "💾 $DISK_FREE free* ₿ $BTC_USD_FMT USD * N$ $BTC_NAD_FMT NAD"

