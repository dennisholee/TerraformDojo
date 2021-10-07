const { EventHubProducerClient } = require("@azure/event-hubs");

const connectionString = "Endpoint=sb://demo-dev-eventhub-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=s6eK2+ymiI5tFl8gAnoMAQT8NxDcSkzInsEy5VKSfAQ=";

const eventHubName = "demo-dev-eventhub";

async function main() {

  // Create a producer client to send messages to the event hub.
  const producer = new EventHubProducerClient(connectionString, eventHubName);

  const partitionIds = await producer.getPartitionIds()
  // Close the producer client.
  await producer.close();

  console.log(partitionIds);
}

main().catch((err) => {
  console.log("Error occurred: ", err);
});
