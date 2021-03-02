package io.forest;

import java.util.Properties;

import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.sink.SinkFunction;
import org.apache.flink.streaming.connectors.kinesis.FlinkKinesisConsumer;
import org.apache.flink.streaming.connectors.kinesis.config.ConsumerConfigConstants;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class StreamJob {
	private static final String region = "us-west-2";
	private static final String inputStreamName = "cloudfront-kstream";
//	private static final String outputStreamName = "ExampleOutputStream";
//	private static final String DEFAULT_STREAM_NAME = "TimestreamTestStream";
	
	private static final Logger LOG = LoggerFactory.getLogger(StreamJob.class);

	private static DataStream<String> createSourceFromStaticConfig(StreamExecutionEnvironment env) {
		Properties inputProperties = new Properties();
		inputProperties.setProperty(ConsumerConfigConstants.AWS_REGION, region);
		inputProperties.setProperty(ConsumerConfigConstants.STREAM_INITIAL_POSITION, "TRIM_HORIZON");

		return env.addSource(new FlinkKinesisConsumer<>(inputStreamName, new SimpleStringSchema(), inputProperties));
	}

//	private static FlinkKinesisProducer<String> createSinkFromStaticConfig() {
//		Properties outputProperties = new Properties();
//		outputProperties.setProperty(ConsumerConfigConstants.AWS_REGION, region);
//		outputProperties.setProperty("AggregationEnabled", "false");
//
//		FlinkKinesisProducer<String> sink = new FlinkKinesisProducer<>(new SimpleStringSchema(), outputProperties);
//		sink.setDefaultStream(outputStreamName);
//		sink.setDefaultPartition("0");
//		return sink;
//	}
	
	private static SinkFunction<TimestreamPoint> foo() {
		
		String region = "us-west-2";//parameter.get("Region", "us-east-1").toString();
		String databaseName = "kdaflink"; //parameter.get("TimestreamDbName", "kdaflink").toString();
		String tableName = "kinesisdata1";//parameter.get("TimestreamTableName", "kinesisdata1").toString();
		int batchSize = 50; //Integer.parseInt(parameter.get("TimestreamIngestBatchSize", "50"));

		
		TimestreamInitializer timestreamInitializer = new TimestreamInitializer(region);
		timestreamInitializer.createDatabase(databaseName);
		timestreamInitializer.createTable(databaseName, tableName);

		SinkFunction<TimestreamPoint> sink = new TimestreamSink(region, databaseName, tableName, batchSize);
		return sink;
	}

	public static void main(String[] args) throws Exception {
		// set up the streaming execution environment
		final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

		/*
		 * if you would like to use runtime configuration properties, uncomment the
		 * lines below DataStream<String> input =
		 * createSourceFromApplicationProperties(env);
		 */
		DataStream<String> input = createSourceFromStaticConfig(env);
		DataStream<TimestreamPoint> mappedInput =
				input.map(new JsonToTimestreamPayloadFn()).name("MaptoTimestreamPayload");
		mappedInput.addSink(foo());

		env.execute("Flink Streaming Java API Skeleton");
	}
}
