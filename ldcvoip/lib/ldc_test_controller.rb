# encoding: utf-8
#testing

class LdcTestController < Adhearsion::CallController

  SND_DIR='/var/lib/asterisk/sounds/en'

  attr_accessor :number, :attempt
  

  def run
    answer
    menu "#{SND_DIR}/conf-usermenu.gsm", timeout: 3, tries: 3 do
      match 1, CheckPIN
      match 2, SayTime
      match 3..10 do |dialed|
        play_digits(dialed)
        hangup
      end
      failure do
        play "#{SND_DIR}/conf-onlyperson.gsm"
        hangup
      end
    end
  end

end

class CheckPIN < Adhearsion::CallController

  def run
    result = ask '/var/lib/asterisk/sounds/en/conf-getpin.gsm', terminator: '#'
    if result.response.to_i == 44
      play_digits(result.response)
      play '/var/lib/asterisk/sounds/en/auth-thankyou.gsm'
      #dial user here...doesn't actually call until client hangs up? Why?
      invoke LinkUsers
      #case status.result
      #when :answer
      #when :error, :timeout, :no_answer
      #  hangup
      #end
    else
      play_digits(result.response)
      play '/var/lib/asterisk/sounds/en/auth-incorrect.gsm'
    end
    hangup
  end

end

class LinkUsers < Adhearsion::CallController

  def run
    # same issues with both methods
    #Adhearsion::OutboundCall.originate 'SIP/crc2', from: 'SIP/crc'
    dial 'SIP/crc2', from: 'SIP/crc'
  end

end

class SayTime < Adhearsion::CallController

  def run
    t = Time.now
    date = t.to_date
    date_format = 'ABdY'
    play_time date, :format => date_format
    hangup
  end

end
