// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.



import com.microsoft.azure.sdk.iot.device.*;
import com.microsoft.azure.sdk.iot.device.exceptions.IotHubClientException;
import com.microsoft.azure.sdk.iot.device.transport.IotHubConnectionStatus;
import com.microsoft.azure.sdk.iot.provisioning.security.SecurityProvider;

import java.security.GeneralSecurityException;
import java.security.cert.X509Certificate;
import javax.net.ssl.SSLContext;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.io.IOException;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;


/** Sends a number of event messages in batch to an IoT Hub. */
public class ConnectTest
{
    private  static final List<Message> failedMessageListOnClose = new ArrayList<>(); // List of messages that failed on close
    private  static final int D2C_MESSAGE_TIMEOUT = 2000; // 2 seconds
    
    /**
     * Sends a number of messages to an IoT or Edge Hub. Default protocol is to
     * use MQTT transport.
     *
     * @param args
     * args[0] = IoT Hub or Edge Hub connection string
     * args[1] = number of messages to send
     * args[2] = protocol (optional, one of 'mqtt' or 'amqps' or 'https' or 'amqps_ws')
     */
    public static void main(String[] args)
            throws IOException, URISyntaxException, IotHubClientException
    {
        System.out.println("Starting...");
        System.out.println("Beginning setup.");

        String deviceId = args[0];
        String protocolStr = args[1];
        String connString = args[2];

        try
        {
        }
        catch (NumberFormatException e)
        {
            System.out.format(
                    "Could not parse the number of requests to send. "
                            + "Expected an int but received:\n%s.\n", args[1]);
            return;
        }
        
        IotHubClientProtocol protocol;
        if (args.length == 3)
        {
            protocol = IotHubClientProtocol.MQTT;
        }
        else
        {
            if (protocolStr.equals("https"))
            {
                protocol = IotHubClientProtocol.HTTPS;
            }
            else if (protocolStr.equals("amqps"))
            {
                protocol = IotHubClientProtocol.AMQPS;
            }
            else if (protocolStr.equals("mqtt"))
            {
                protocol = IotHubClientProtocol.MQTT;
            }
            else if (protocolStr.equals("amqps_ws"))
            {
                protocol = IotHubClientProtocol.AMQPS_WS;
            }
            else if (protocolStr.equals("mqtt_ws"))
            {
                protocol = IotHubClientProtocol.MQTT_WS;
            }
            else
            {
                System.out.format(
                        "Expected argument 2 to be one of 'mqtt', 'https', 'amqps' or 'amqps_ws' but received %s\n"
                                + "The program should be called with the following args: \n"
                                + "1. [Device connection string] - String containing Hostname, Device Id & Device Key in one of the following formats: HostName=<iothub_host_name>;DeviceId=<device_id>;SharedAccessKey=<device_key>\n"
                                + "2. [number of requests to send]\n"
                                + "3. (mqtt | https | amqps | amqps_ws | mqtt_ws)\n",
                        protocolStr);
                return;
            }
        }

        System.out.println("Successfully read input parameters.");
        System.out.format("Using communication protocol %s.\n", protocol.name());

        //https://github.com/Azure/azure-iot-sdk-java/blob/04b0a74353b19893e2e8c3be613e7d95040e696d/device/iot-device-samples/send-event-x509/src/main/java/samples/com/microsoft/azure/sdk/iot/SendEventX509.java

        String pubKey = new String(Files.readAllBytes(Paths.get("/home/ablythe/iot-edge-device-identity-iotedge-child1-primary.cert.pem")));
        String privKey = new String(Files.readAllBytes(Paths.get("/home/ablythe/iot-edge-device-identity-iotedge-child1-primary.key.pem")));

        System.out.format("pubKey: %s", pubKey);
        System.out.format("privKey: %s", privKey);

        SSLContext sslContext = null;

        try
        {
            sslContext = SSLContextBuilder.buildSSLContext(pubKey, privKey);        
        }
        catch(GeneralSecurityException e)
        {
            e.printStackTrace(); // Trace the exception
            return;
        }

        ClientOptions options = ClientOptions.builder().sslContext(sslContext).build();
        DeviceClient client = null;

        client = new DeviceClient(connString, protocol, options);

        // if(connString.toLowerCase().contains("SharedAccessKey"))
        // {
        //     client = new DeviceClient(connString, protocol, options);
        // }
        // else
        // {
        //     client = DeviceClient.createFromSecurityProvider()
        // }

        System.out.println("Successfully created an IoT Hub client.");

        client.setConnectionStatusChangeCallback(new IotHubConnectionStatusChangeCallbackLogger(), new Object());

        client.open(false);

        System.out.println("Opened connection to IoT Hub.");
        System.out.println("Sending the following event messages in batch:");

        List<Message> messageList = new ArrayList<>();

        String messageId = java.util.UUID.randomUUID().toString();
        String msgStr = "{\"deviceId\":\"" + deviceId +"\",\"messageId\":\"" + messageId + "\"}";

        
        Message msg = new Message(msgStr);
        msg.setContentType("application/json");
        msg.setMessageId(java.util.UUID.randomUUID().toString());
        //msg.setExpiryTime(D2C_MESSAGE_TIMEOUT);

        System.out.println(msgStr);

        messageList.add(msg);

        try
        {
            MessageSentCallbackImpl messageSentCallbackImpl = new MessageSentCallbackImpl();
            client.sendEventAsync(msg, messageSentCallbackImpl, null);
        }
        catch (Exception e)
        {
            e.printStackTrace(); // Trace the exception
        }

        System.out.println("Wait for " + D2C_MESSAGE_TIMEOUT / 1000 + " second(s) for response from the IoT Hub...");

        // Wait for IoT Hub to respond.
        try
        {
            Thread.sleep(D2C_MESSAGE_TIMEOUT);
        }

        catch (InterruptedException e)
        {
            e.printStackTrace();
        }

        // close the connection
        System.out.println("Closing");
        client.close();

        if (!failedMessageListOnClose.isEmpty())
        {
            System.out.println("List of messages that were cancelled on close:" + failedMessageListOnClose.toString());
        }

        System.out.println("Shutting down...");
    }

    @SuppressWarnings("unchecked")
    protected static class MessageSentCallbackImpl implements MessageSentCallback
    {
        public void onMessageSent(Message message, IotHubClientException exception, Object context)
        {
            IotHubStatusCode status = exception == null ? IotHubStatusCode.OK : exception.getStatusCode();
            System.out.println("IoT Hub responded to the batch message with status " + status.name());

            if (status==IotHubStatusCode.MESSAGE_CANCELLED_ONCLOSE)
            {
                failedMessageListOnClose.add(message);
            }
        }
    }

    protected static class IotHubConnectionStatusChangeCallbackLogger implements IotHubConnectionStatusChangeCallback
    {
        @Override
        public void onStatusChanged(ConnectionStatusChangeContext connectionStatusChangeContext)
        {
            IotHubConnectionStatus status = connectionStatusChangeContext.getNewStatus();
            IotHubConnectionStatusChangeReason statusChangeReason = connectionStatusChangeContext.getNewStatusReason();
            Throwable throwable = connectionStatusChangeContext.getCause();

            System.out.println();
            System.out.println("CONNECTION STATUS UPDATE: " + status);
            System.out.println("CONNECTION STATUS REASON: " + statusChangeReason);
            System.out.println("CONNECTION STATUS THROWABLE: " + (throwable == null ? "null" : throwable.getMessage()));
            System.out.println();

            if (throwable != null)
            {
                throwable.printStackTrace();
            }

            if (status == IotHubConnectionStatus.DISCONNECTED)
            {
                System.out.println("The connection was lost, and is not being re-established." +
                        " Look at provided exception for how to resolve this issue." +
                        " Cannot send messages until this issue is resolved, and you manually re-open the device client");
            }
            else if (status == IotHubConnectionStatus.DISCONNECTED_RETRYING)
            {
                System.out.println("The connection was lost, but is being re-established." +
                        " Can still send messages, but they won't be sent until the connection is re-established");
            }
            else if (status == IotHubConnectionStatus.CONNECTED)
            {
                System.out.println("The connection was successfully established. Can send messages.");
            }
        }
    }
}