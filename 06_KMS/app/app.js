'use strict'

const kms = require('@google-cloud/kms')
const client = new kms.KeyManagementServiceClient()


const projectId          = 'foo789-terraform-admin'
const locationId         = 'asia-east2'
const keyRingId          = 'keyring-example'
const cryptoKeyId        = 'kms-secret'

const name = client.cryptoKeyPath(
    projectId,
    locationId,
    keyRingId,
    cryptoKeyId
  )


const plaintext = Buffer.from('test');

let encryptRequest = {
  name: name,
  plaintext: plaintext,
}

client.encrypt(encryptRequest).then (
  responses => {
    const response = responses[0]
    let decryptRequest = {
	name: name,
	ciphertext: response.ciphertext
    }
    client.decrypt(decryptRequest).then (
      responses => {
        const response = responses[0]
        console.log(response.plaintext.toString())
      }
    )
}).catch(
  console.error
)
