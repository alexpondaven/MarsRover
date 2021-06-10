TO SERVER:
int     32  coordinates (*2)
int     32  speed
int     32  direction (just left right forward backward)
string  NA  alerts (optional)
/       NA  obstacles information (TBC)

{
    coordinates: [int,int],
    speed: int,
    direction: int (0-forward, 1-backward, 2-left, 3-right),
    obstacle: [[int,x5],[float,x5],[float,x5]] (color, angle, distance)
}

obstacle
{
    color: int (1-red 2-pink 3-yellow 4-green 5-blue)
    angle: float,   (radian)
    distance: float (mm)
}
if color==-1 => no obstacle 

1-red 2-pink 3-yellow 4-green 5-blue


TO BOARD: 2000
{
    mode: int (0 - direciton, 1- position, 2-exploration),
    direciton: [byte,byte,byte,byte],
    position: [int,int],
    video: int (0-inf)
    videodetail: [{},{},..]
}
{
    color: int,
    type: 'h'|'s'|'v'|'e'|'g',
    state: bool (true is max, false is min)|(true is add, false is minus),
    value: int
}