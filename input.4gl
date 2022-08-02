CONSTANT PORT=9100
MAIN
  DEFINE data STRING
  --start our http server/socket server combination
  RUN "fglrun srv" WITHOUT WAITING
  --probing the server to avoid failing of our webco SSE request
  CALL probe(PORT) 
  OPEN FORM f FROM arg_val(0)
  DISPLAY FORM f
  LET int_flag=FALSE
  --input from the webco
  INPUT BY NAME data ATTRIBUTE(UNBUFFERED)
    BEFORE INPUT
      CALL setup_sse("http://localhost:9100/SSE")
    ON ACTION data_available
      DISPLAY SFMT("got data:%1", data) TO te
      DISPLAY "got data:", data
  END INPUT
  IF NOT int_flag THEN
    DISPLAY "data:",data
  END IF
  --terminate the server
  RUN "fglrun sendcode exit_server"
END MAIN

FUNCTION setup_sse(url)
  DEFINE url STRING
  DISPLAY SFMT("activate server side events on:%1 ...", url) TO te
  CALL ui.Interface.frontCall(
      "webcomponent", "call", ["formonly.data", "setURL", url], [])
END FUNCTION

FUNCTION probe(port INT)
  DEFINE i INT
  FOR i = 1 TO 5
    IF probeSrv(port) THEN
      --found
      RETURN
    END IF
    SLEEP 1
  END FOR
  CALL myErr("timeout probing srv")
END FUNCTION

FUNCTION writeLine(c base.Channel, s STRING)
  LET s = s, '\r'
  CALL c.writeLine(s)
END FUNCTION

FUNCTION probeSrv(port INT) RETURNS BOOLEAN
  DEFINE c base.Channel
  DEFINE s STRING
  DEFINE found BOOLEAN
  LET c = base.Channel.create()
  CALL log(SFMT("probe srv on port:%1...", port))
  TRY
    CALL c.openClientSocket("127.0.0.1", port, "u", 1)
  CATCH
    CALL log(SFMT("probe failed:%1", err_get(status)))
    RETURN FALSE
  END TRY
  CALL log("gwa probe ok")
  -- write header
  LET s = "GET /PROBE HTTP/1.1"
  CALL writeLine(c, s)
  CALL writeLine(c, "Host: localhost")
  CALL writeLine(c, "User-Agent: gwaprobe")
  CALL writeLine(c, "Accept: */*")
  CALL writeLine(c, "Connection: close")
  CALL writeLine(c, "")

  LET found = read_response(c)
  CALL c.close()
  RETURN found
END FUNCTION

FUNCTION read_response(c) RETURNS BOOLEAN
  DEFINE c base.Channel
  DEFINE s STRING
  WHILE NOT c.isEof()
    LET s = c.readLine()
    LET s = s.toLowerCase()
    DISPLAY SFMT("gwasrv answer:%1", s)
    IF (s == "http/1.1 200 probe ok") OR (s MATCHES "server: gws server*") THEN
      RETURN TRUE
    END IF
    IF s.getLength() == 0 THEN
      EXIT WHILE
    END IF
  END WHILE
  RETURN FALSE
END FUNCTION

FUNCTION printStderr(errstr STRING)
  DEFINE ch base.Channel
  LET ch = base.Channel.create()
  CALL ch.openFile("<stderr>", "w")
  CALL ch.writeLine(errstr)
  CALL ch.close()
END FUNCTION

FUNCTION log(msg STRING)
  DISPLAY "log:",msg
END FUNCTION

FUNCTION myErr(errstr STRING)
  CALL printStderr(
      SFMT("ERROR:%1 stack:\n%2", errstr, base.Application.getStackTrace()))
  EXIT PROGRAM 1
END FUNCTION
