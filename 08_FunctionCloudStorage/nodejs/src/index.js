const vision     = require('@google-cloud/vision')
const {BigQuery} = require('@google-cloud/bigquery')
const {PubSub}   = require('@google-cloud/pubsub')

exports.healthz = (req, res) => {
    res.status(200).send("hello")
}

exports.scanImage = async (data, context) => {
    const file = data

    console.log(JSON.stringify(file))

    const inputFile = `gs://${file.bucket}/${file.name}`

    const client = new vision.ImageAnnotatorClient()
    const request = {image: {source: {imageUri: inputFile}}};
    const results = await client.landmarkDetection(request);
    console.log('RESULT: ' + JSON.stringify(results))
    const landmarks = results[0].landmarkAnnotations
    const landmark = landmarks.length >= 1 ? landmarks[0]['description'] : ''
    console.log(`landmark: ${landmark}`)

    // Push data to bigquery's pubsub
    const pubsub = new PubSub()
    const dataBuffer = Buffer.from(JSON.stringify({'file': `${inputFile}`, 'landmark': `${landmark}`}));
    const topicName = 'vision-bq-pub-bq-topic'
    const messageId = await pubsub.topic(topicName).publish(dataBuffer);
    console.log(`Message ${messageId} published.`);  
}

exports.publishBigQuery = async (data, context) => {
    const datasetId = "vision_bq_dataset_id"
    const tableId = "bar"
    const pubSubMessage = data; 
    
    const payload = JSON.parse(Buffer.from(pubSubMessage.data, 'base64').toString())
    console.log(`Payload: ${JSON.stringify(payload)}`)

    const bigquery = new BigQuery()
    await bigquery
      .dataset(datasetId)
      .table(tableId)
      .insert(payload)
}
