#!/usr/bin/ruby
# http://d.hatena.ne.jp/urekat/20070112/1168614435

require 'osx/cocoa'
OSX.require_framework "WiiRemote"

require 'classifier'

def say(str)
  Thread.start { system "say '#{str}'" }
end

class WiiRemoconTest < OSX::NSObject
  def initialize
    @discovery = nil
    @remote = nil
  end

  def init
    @discovery = OSX::WiiRemoteDiscovery.alloc.init
    @discovery.setDelegate(self)
    @discovery.start
    return self
  end

  def WiiRemoteDiscovered(remote)
    puts "WiiRemoteDiscovered remote=#{remote.inspect}"
    @remote = Remote.alloc.init
    @remote.start(remote)
    say "connected"
    @discovery.stop
  end

  def WiiRemoteDiscoveryError(code)
    puts "WiiRemoteDiscoveryError code=%x" % code
  end

  objc_method :WiiRemoteDiscovered,     %w{void id}
  objc_method :WiiRemoteDiscoveryError, %w{void int}
end

class Remote < OSX::NSObject
  def init
    return self
  end
  def Remote.callback(remote)
    proc {
      remote.setMotionSensorEnabled(false)
      remote.closeConnection
    }
  end

  def start(remote)
    @remote = remote
    @remote.setDelegate(self)
    @remote.setMotionSensorEnabled(true)
    ObjectSpace.define_finalizer(self, Remote.callback(@remote))
    @record_mode = false
    @recorded_data = []
    @t0 = nil
  end

  def irPointMovedX_Y_wiiRemote(px, py, wiiRemote)
    puts "irPointMovedX_Y"
  end

  def buttonChanged_isPressed_wiiRemote(btn_type, is_pressed, wiiRemote)
    puts "buttonChanged_isPressed #{btn_type} #{is_pressed}                "
    if btn_type == 0
      if is_pressed == 1
        # ボタンが押された: 記録開始
        @record_mode = true
        @recorded_data = []
        @t0 = Time.now
      else
        # ボタンが離された: 記録完了, 認識
        @record_mode = false
        # 現在のデータを書き出す
        open("sequence.txt", "w") do |f|
          @recorded_data.each do |v|
            f.puts "%f %d %d %d" % v
          end
        end
        # 識別結果を返す
        say $classifier.classify(@recorded_data)
      end
    end
    if btn_type == 5 && is_pressed == 1
      system("sh show.sh sequence.txt")
    end
  end

  def accelerationChanged_accX_accY_accZ_wiiRemote(type, ax, ay, az, wiiRemote)
    #p "accelerationChanged_accX_accY_accZ(%d,%d,%d,%d)" % [type,ax,ay,az]
    #p "*" * (ax/2)
    if @record_mode
      @recorded_data << [Time.now-@t0, ax, ay, az]
    end
    v = Math.sqrt((ax-127)**2+(ay-127)**2+(az-127)**2)
    print "%f %3d %3d %3d %f\r" % [Time.now.to_f, ax, ay, az, v]
    STDOUT.flush
  end

  def joyStickChanged_tiltX_tiltY_wiiRemote(type, tilt_x, tilt_y, wiiRemote)
    puts "joyStickChanged_tiltX_tiltY"
  end

  def wiiRemoteDisconnected(device)
    puts "wiiRemoteDisconnected"
    say "disconnected"
  end

  objc_method :irPointMovedX_Y_wiiRemote, %w{void float float id}
  objc_method :buttonChanged_isPressed_wiiRemote, %w{void ushort char id}
  objc_method :accelerationChanged_accX_accY_accZ_wiiRemote, %w{void ushort uchar uchar uchar id}
  objc_method :joyStickChanged_tiltX_tiltY_wiiRemote, %w{void ushort uchar uchar id}
  objc_method :wiiRemoteDisconnected, %w{void id}
  objc_method :closeConnection, %w{id}
end

test = WiiRemoconTest.alloc.init

$classifier = Classifier.new(File.join(File.dirname(__FILE__), "templates"))
OSX::NSRunLoop.currentRunLoop.run
