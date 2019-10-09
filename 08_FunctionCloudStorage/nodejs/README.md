Deploy cloud storage object creation trigger function
```sh
gcloud functions deploy scanImage --region asia-east2 --runtime nodejs8 --trigger-resource foo789-terraform-admin --trigger-event google.storage.object.finalize
```

Deploy pubsub function
```sh
gcloud functions deploy publishBigQuery --region asia-east2 --runtime nodejs8 --trigger-topic vision-bq-pub-bq-topic
```

Test function
```sh
gcloud pubsub topics publish vision-bq-pub-bq-topic --message "HELLO FOO"
```


