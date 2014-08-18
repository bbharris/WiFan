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

const html = @"<!DOCTYPE html>
<html lang='en'>
    <head>
        <style> body {background-color:black;}</style>
        <meta charset='utf-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0'>
        <meta name='apple-mobile-web-app-capable' content='yes'>
        <script src='https://code.jquery.com/jquery-1.9.1.min.js'></script>
        <script src='https://code.jquery.com/jquery-migrate-1.2.1.min.js'></script>
        <script src='https://d2c5utp5fpfikz.cloudfront.net/2_3_1/js/bootstrap.min.js'></script>
        <link href='https://d2c5utp5fpfikz.cloudfront.net/2_3_1/css/bootstrap.min.css' rel='stylesheet'>
        <link href='https://d2c5utp5fpfikz.cloudfront.net/2_3_1/css/bootstrap-responsive.min.css' rel='stylesheet'>
        <title>Fan Controller</title>
    </head>
    <body style='background-color:#000000'>
        <script type='text/javascript'>

            $(window).resize(function(){
                $('.className').css({
                    position:'absolute',
                    left: ($(window).width() - $('.className').outerWidth())/2,
                    top: ($(window).height() - $('.className').outerHeight())/2
                });
            });
        
            $(document).ready(function () {
                function reorient(e) {
                    var p = window.orientation;
                    if(p == 90){
                        $('body > div').css('-webkit-transform', 'rotate(-90deg)');
                        $('.className').css({
                            position:'absolute',
                            top: ($(window).width() - $('.className').outerWidth())/2,
                            left: ($(window).height() - $('.className').outerHeight())/2
                        });
                    }else if(p == 270){
                        $('body > div').css('-webkit-transform', 'rotate(90deg)');
                        $('.className').css({
                            position:'absolute',
                            top: ($(window).width() - $('.className').outerWidth())/2,
                            left: ($(window).height() - $('.className').outerHeight())/2
                        });
                    }else{
                        $('body > div').css('-webkit-transform', '');
                        $('.className').css({
                            position:'absolute',
                            left: ($(window).width() - $('.className').outerWidth())/2,
                            top: ($(window).height() - $('.className').outerHeight())/2
                        });
                    }
                    
                }
                window.onorientationchange = reorient;
                window.setTimeout(reorient, 0);
                
            });
        
            
            document.ontouchstart = function(e){e.preventDefault();}
            
            function sendToImp(value){
                if (window.XMLHttpRequest) {devInfoReq=new XMLHttpRequest();}
                else {devInfoReq=new ActiveXObject('Microsoft.XMLHTTP');}
                try {
                    devInfoReq.open('POST', document.URL, false);
                    devInfoReq.send(value);
                } catch (err) {
                    console.log('Error parsing device info from imp');
                }
            }
            function fanOff(){ sendToImp('fanOff'); }
            function fanLow(){ sendToImp('fanLow'); }
            function fanMed(){ sendToImp('fanMed'); }
            function fanHigh(){sendToImp('fanHigh');}
            function fanRev(){ sendToImp('fanRev'); }
            function light() { sendToImp('light');  }
        </script>
        <div class='container'>
            <br>
            <div class='well' style='width: 240px; margin: 0 auto 10px; background-color:#1F1F1F'>
                <button class='btn btn-primary btn-large btn-block' onclick='light()'  ontouchstart='light()' style='height:75px'>Light</button>
                <br>
                <button class='btn btn-primary btn-large btn-block' onclick='fanOff()' ontouchstart='fanOff()' style='height:75px'>Fan Off</button>
                <br>
                <button class='btn btn-primary btn-large btn-block' onclick='fanLow()' ontouchstart='fanLow()' style='height:75px'>Fan Low</button>
                <br>
                <button class='btn btn-primary btn-large btn-block' onclick='fanMed()' ontouchstart='fanMed()' style='height:75px'>Fan Medium</button>
            </div>
        </div>
    </body>
</html>";

//<button class='btn btn-primary btn-large btn-block' onclick='fanHigh()'>Fan High</button>
//<button class='btn btn-primary btn-large btn-block' onclick='fanRev()'>Reverse</button>

server.log("Agent Starting");

dip <- 0x0F;

http.onrequest(function(request,res){
    if (request.body == "") {
        server.log("Request for HTML");
        res.send(200, html);
    }else{
        if(request.body == "light" ||
        request.body == "fanOff" ||
        request.body == "fanLow" ||
        request.body == "fanMed" ||
        request.body == "fanHigh" ||
        request.body == "fanRev" ){
            server.log("Command: "+request.body);
            device.send("command", {state = request.body, channel = dip});
            res.send(200,"OK");
        }else{
            server.log("Unrecognized Command: " + request.body);
            res.send(400, "Unrecognized Command.");
        }
    }
});

device.on("done", function(d) { server.log("Command Complete.");});
