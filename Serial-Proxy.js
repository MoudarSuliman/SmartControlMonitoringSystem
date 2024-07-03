const { SerialPort } = require('serialport');
const { ReadlineParser } = require('@serialport/parser-readline');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require(''); 

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: ""
});

const db = admin.firestore();

function isValidJSON(string) {
    try {
        JSON.parse(string);
    } catch (e) {
        return false;
    }
    return true;
}

const listPorts = async () => {
    const ports = await SerialPort.list();
    return ports;
}

const getArduinoPath = async () => {
    const ports = await listPorts();
    const foundPorts = ports.filter(({friendlyName}) => friendlyName && friendlyName.indexOf("USB-SERIAL CH340") != -1);
    if(!foundPorts.length){
        return null;
    }
    console.log("Found Ports:", foundPorts);
    console.log("Choosing first port:", foundPorts[0]);
    return foundPorts[0].path;
}

async function listenForLightChanges(port) {
    const lightRef = db.collection('lights').doc('ednpr1YxRNjbseIofivM'); 
    lightRef.onSnapshot(docSnapshot => {
        let lightStatus = docSnapshot.data().On;
        console.log(`Received light status update: ${lightStatus}`);
        port.write(`${lightStatus}`, function(err) {
            if (err) {
                console.log('Error on write: ', err.message);
            }
        });
    }, err => {
        console.log(`Encountered error: ${err}`);
    });
}

async function postTemperature(value) {
    const docRef = db.collection('temperatures').doc();
    await docRef.set({
        value: value,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('Temperature data sent to Firestore');
}

const startProxy = async() => {
    const path = await getArduinoPath();
    if (!path) {
        console.log("Arduino not found. Please check the connection.");
        return;
    }
    console.log(path);
    const port = new SerialPort({ path, baudRate: 19200 });
    const parser = port.pipe(new ReadlineParser({ delimiter: '\n' })); // Read the port data
    

    port.on("open", () => {
      console.log('Started connection with Arduino');
      listenForLightChanges(port)
    });



    parser.on('data', data =>{
        if(isValidJSON(data)){
            console.log('Arduino JSON:', JSON.parse(String(data)));
            let parsedData = JSON.parse(String(data));
            if (parsedData.temperature) {
                postTemperature(parsedData.temperature);
            }
        }else if(data.startsWith("DEVICE_ID:")) {
            // Extract device ID
            let deviceId = data.split(":")[1].trim();
            console.log('Received Device ID:', deviceId);
            // Send device ID to Firestore as document ID
            db.collection('allDevices').doc(deviceId).set({
                connected: true,
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            })
            .then(() => console.log(`Device ID ${deviceId} sent to Firestore`))
            .catch((error) => console.error("Error writing device ID to Firestore: ", error));
        }else{
            console.log('Arduino Data:', data);    
        }
    });    
}

startProxy();
