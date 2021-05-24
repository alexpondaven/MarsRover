import Alert from './Alert.js'

function Alerts({alerts}) {
    return (
        <div className="Card2">
            <h3>Alerts/Notifications:</h3>
            <>
            {alerts.map((alert, index) => (
                <Alert key={index} alert={alert} />
            ))}
            </>
        </div>
    )
}

export default Alerts
