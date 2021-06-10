import Video_Slider from './VideoPage_Slider.js'

function VideoPage_Sliders({color, forcefetch}) {
    const onChange = (name,value) => {
        console.log(color + " " + name + ": " + value);
        var body = {
            name: 'hsv',
            color: color,
            type: name,
            value: value
        }
        fetch('http://localhost:5000/videosetting', {
          method: 'POST',
          headers: {
            'Content-type': 'application/json',
          },
          body: JSON.stringify(body),
        })
    }

    return (        
        <div>
            <Video_Slider name='Hue' color={color} onChange={onChange} forcefetch={forcefetch} tooltip='Hue is the color portion of the model'/>
            <Video_Slider name='Saturation' color={color} onChange={onChange} forcefetch={forcefetch} tooltip='Saturation describes the amount of gray in a particular color. Reducing this component toward zero introduces more gray and produces a faded effect.'/>
            <Video_Slider name='Value' color={color} onChange={onChange} forcefetch={forcefetch} tooltip='Value works in conjunction with saturation and describes the brightness or intensity of the color'/>
        </div>
    )
}

export default VideoPage_Sliders
