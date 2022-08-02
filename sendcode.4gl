MAIN
  DEFINE c base.Channel
  IF num_args()<1 THEN
    DISPLAY "usage: fglrun sendcode <code>"
    EXIT PROGRAM 1
  END IF
  IF length(arg_val(1))==0 THEN
    DISPLAY "code length must be > 0"
    EXIT PROGRAM 1
  END IF
  LET c=base.Channel.create()
  CALL c.openClientSocket("localhost",9200,mode: "w",timeout: 2)
  CALL c.writeLine(arg_val(1))
  CALL c.close()
END MAIN
