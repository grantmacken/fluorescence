

# gcloud setup


## obtaining a service account key

Google Compute Engine comes with a default service account.
To check this run.

```
gcloud iam service-accounts list | grep -oP '^.+default service account\s+\K[a-z0-9-\.@]+
```

Create a key using this default account.

```
gcloud iam service-accounts keys create ~/key.json \
--iam-account $(gcloud iam service-accounts list | grep -oP '^.+default service account\s+\K[a-z0-9-\.@]+') 
```

Then encode this key.json file as base64 and paste into cliboard

```
openssl base64 -in ~/key.json | xclip -sel clip

```


In [github repo](https://github.com/grantmacken/xq/settings/secrets)
settings paste this value as a secret key named `GCE_SERVICE_ACCOUNT_KEYG`


.

/secrets/new

599233106498-compute@developer.gserviceaccount.com


