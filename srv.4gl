--small trial to push data into a webcomponent via SSE
--2 TCP servers are involved, the GWS server and a Genero server socket
OPTIONS
SHORT CIRCUIT
IMPORT com
DEFINE _channel base.Channel

DEFINE _lastEventId INT
MAIN
  DEFINE path, url, code STRING
  DEFINE req com.HttpServiceRequest
  CALL fgl_setenv("FGLAPPSERVER", "9100")
  --do I need this option?
  CALL com.WebServiceEngine.SetOption("server_readwritetimeout", -1)
  CALL com.WebServiceEngine.Start()
  LET _channel = base.Channel.create()
  CALL _channel.openServerSocket("127.0.0.1", 9200, "u")
  WHILE TRUE
    LET req = com.WebServiceEngine.GetHTTPServiceRequest(-1)
    IF req IS NULL THEN
      DISPLAY "ERROR: no HTTPServiceRequest."
      EXIT WHILE
    ELSE
      LET url = req.getUrl()
      LET path = req.getUrlPath()
      DISPLAY "URL:", url, ",path:", path, ",method:", req.getMethod()
      CASE
        WHEN path.getIndexOf("/SSE", 1) > 0
          DISPLAY "SSE request seen, wait for code data.."
          --wait for the connect of the scanner and reads the code
          LET code = _channel.readLine()
          DISPLAY "code:",code
          IF code="exit_server" THEN
            DISPLAY "exit srv"
            EXIT PROGRAM
          END IF
          --voodoo line,cause the server socket to close the incoming connection
          CALL _channel.writeLine(ASCII(26))
          CALL sendDataToWebCo(req, code)
        WHEN path=="/PROBE"
          CALL req.setResponseHeader("Content-Type", "text/plain")
          CALL req.sendTextResponse(200, "probe ok", DATE)
        OTHERWISE
          CALL req.sendTextResponse(
              code: 400, description: "Not found", txt: "Not found")
      END CASE
    END IF
  END WHILE
END MAIN

FUNCTION sendDataToWebCo(req com.HttpServiceRequest, code STRING)
  DEFINE sse STRING
  CALL req.setResponseHeader("Access-Control-Allow-Origin", "*")
  CALL req.setResponseHeader("Content-Type", "text/event-stream")
  LET _lastEventId = _lastEventId + 1
  --format the server side event
  LET sse = SFMT("id:%1\nretry:10\n", _lastEventId)
  LET sse = sse, "event:code\n" --set the special code event type
  LET sse = sse, SFMT("data: %1\n\n", code)
  CALL req.sendTextResponse(200, "OK", sse)
  DISPLAY "did send:", sse
END FUNCTION
