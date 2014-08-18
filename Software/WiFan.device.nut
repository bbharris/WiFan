/* 
 * Wireless Ceiling Fan Control Protocol
 * Copyright (C) 2014 Brandon Harris
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software
 * and associated documentation files (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge, publish, distribute,
 * sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or
 * substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
 * BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

// Description of protocol:
// Logic 0 is transmitted as 640us low followed by 320us high
// Logic 1 is transmitted as 320us low followed by 640us high
// For this code we will treat each logic bit as 3x 320us long pulses, thus:
// Logic 0 is 2 low pulses followed by 1 high pulse
// Logic 1 as 1 low pulse followed by 2 high pulses
//
// Each command consists of 13 bits, the line should go low for 11ms between each command
// The 13 bits are as follows:
// 0-1-[DIP1]-[DIP2]-[DIP3]-[DIP4]-0-[FanHigh]-[FanMed]-[FanLow]-[FanReverse]-[Light]
//
// DIP* is equal to the settings of the DIP switches on the receiver and asks as a 4-bit address
// Light is a toggle, so 0 is stay the same, 1 is change current state (on->off, off->on)

imp.enableblinkup(false);
server.log("Device Starting");

//=================================================================================================//
// GLOBALS AND CONSTANTS
//=================================================================================================//

// SPI is used to effectively bit-bang the remote protocol
// Data is clocked out from the MOSI line on SPI257 (Pin 7).
const CLK_SPEED                  = 1875; 
const SPI_BYTES_PER_PROTOCOL_BIT = 225;  //CLK_SPEED/8 * 0.960us/bit
const REPEAT                     = 5;    //Number of times to send the command

spi <- hardware.spi257;

ZEROBLOB <- blob(SPI_BYTES_PER_PROTOCOL_BIT);
ONEBLOB  <- blob(SPI_BYTES_PER_PROTOCOL_BIT);

commandBlob <- blob(SPI_BYTES_PER_PROTOCOL_BIT*13 + 1); //We add a zero byte so data goes low at the end

//=================================================================================================//
// Setup Outputs and build blobs
//=================================================================================================//
spi.configure(CLOCK_IDLE_LOW, CLK_SPEED);
//server.log("Clock: "+spi.configure(CLOCK_IDLE_HIGH, 1));

for(local i = 0; i < SPI_BYTES_PER_PROTOCOL_BIT/3 ; i++){
    ZEROBLOB.writen(0x00,'b');
	ONEBLOB.writen(0x00, 'b');
}

for(local i = SPI_BYTES_PER_PROTOCOL_BIT/3; i < 2*SPI_BYTES_PER_PROTOCOL_BIT/3 ; i++){
	ZEROBLOB.writen(0x00,'b');
	ONEBLOB.writen(0xFF, 'b');
}

for(local i = 2*SPI_BYTES_PER_PROTOCOL_BIT/3; i < SPI_BYTES_PER_PROTOCOL_BIT ; i++){
	ZEROBLOB.writen(0xFF,'b');
	ONEBLOB.writen(0xFF, 'b');
}

//=================================================================================================//
// Functions
//=================================================================================================//
function sendCommand(dip, commandStr){
	local commandValid = 0;
	commandBlob.seek(0);

    commandBlob.writeblob(ZEROBLOB);

    commandBlob.writeblob(ONEBLOB);
	

	if(dip & 0x08){	commandBlob.writeblob(ONEBLOB) }
	else{           commandBlob.writeblob(ZEROBLOB)}

	if(dip & 0x04){	commandBlob.writeblob(ONEBLOB) }
	else{           commandBlob.writeblob(ZEROBLOB)}

	if(dip & 0x02){	commandBlob.writeblob(ONEBLOB) }
	else{           commandBlob.writeblob(ZEROBLOB)}

	if(dip & 0x01){	commandBlob.writeblob(ONEBLOB) }
	else{           commandBlob.writeblob(ZEROBLOB)}

	commandBlob.writeblob(ZEROBLOB)

	if(commandStr == "fanHigh"){
		commandValid = 1;
		commandBlob.writeblob(ONEBLOB);
	}else{
		commandBlob.writeblob(ZEROBLOB)
	}

	if(commandStr == "fanMed"){
		commandValid = 1;
		commandBlob.writeblob(ONEBLOB);
	}else{
		commandBlob.writeblob(ZEROBLOB)
	}

	if(commandStr == "fanLow"){
		commandValid = 1;
		commandBlob.writeblob(ONEBLOB);
	}else{
		commandBlob.writeblob(ZEROBLOB)
	}

	if(commandStr == "fanRev"){
		commandValid = 1;
		commandBlob.writeblob(ONEBLOB);
	}else{
		commandBlob.writeblob(ZEROBLOB)
	}
    
    if(commandStr == "fanOff"){
		commandValid = 1;
		commandBlob.writeblob(ONEBLOB);
	}else{
		commandBlob.writeblob(ZEROBLOB)
	}

	if(commandStr == "light"){
		commandValid = 1;
		commandBlob.writeblob(ONEBLOB);
	}else{
		commandBlob.writeblob(ZEROBLOB)
	}

	commandBlob.writen(0x00,'b');

	if(commandValid){
		server.log("Valid Command: "+commandStr);
		for(local i = 0; i < REPEAT; i++){
			spi.write(commandBlob);
			imp.sleep(0.011);
		}
        agent.send("done",0);
	}else{
		server.log("Command not valid: "+commandStr);
	}

}

function scheduleOff(hour, minute, timezone){
    local now = date(time() + timezone*3600);
    local delay = 0;
    
    if(minute >= now.min){
        delay += 60*(minute-now.min);
    }else{
        delay += 60*(minute-now.min + 60);
        hour -= 1;
        server.log("subtracting an hour")
    }
    
    if(hour >= now.hour){
        delay += 3600*(hour-now.hour);
    }else{
        delay += 3600*(hour-now.hour + 24);
    }

    local dh = math.floor((delay/3600))
    local dm = math.floor((delay-dh*3600)/60);

    server.log("Delaying Turn off for: "+dh+" hours, "+dm+" minutes.");
    
    imp.wakeup(delay, function(){sendCommand(0x0F, "fanOff")});
    imp.wakeup(delay + 120, function(){scheduleOff(hour, minute, timezone)});
}


/* Allow the agent to send a command to switch a channel on or off */
agent.on("command",function(command) {
    sendCommand(command.channel, command.state);
});

//scheduleOff(10,49,-7);

scheduleOff(4,0,-7);


// function loop(){
//     sendCommand(0x0F, "light");
//     imp.wakeup(5, loop);
// }
