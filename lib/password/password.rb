# https://gist.github.com/2040373
# Ask for a password from CLI, 
# if it exists.
module Password

  # --- Platform inspectors

  def windows? ; RUBY_PLATFORM =~ /win(32|dows|ce)|djgpp|(ms|cyg|bcc)win|mingw32/i end
  def jruby?   ; RUBY_PLATFORM =~ /java/i      end
  def os2?     ; RUBY_PLATFORM =~ /os2/i       end
  def beos?    ; RUBY_PLATFORM =~ /beos/i      end
  def unix?    ; !jruby? && !windows? && !os2? && !beos? end
                                                                #  NOTE: 99.999% of mac detection code has a subtle flaw.
                                                                #  i.e.:    RUBY_PLATFORM =~ /darwin|apple|mac/i

    def mac?     ; RUBY_PLATFORM =~ /.*(sal|86).*-darwin1/i end #  e.g.. 'x86_64-darwin11.3.0'       MRI 1.9.3      Lion
                                                                #        'x86_64-apple-darwin11.3.0' Rubinius       Lion
                                                                #        'i686-darwin11.3.0'         RubyEnterprise Lion
                                                                #        'universal-darwin10.0'      MacRuby        Lion

    def ios?     ; RUBY_PLATFORM =~ /arm-darwin/i     end       #  e.g., 'arm-darwin9'

                                                                #              Can you spot the implication?

    def linux?   ; RUBY_PLATFORM =~ /linux/i          end
      # patches welcome: rh, oel, sl, slc, cent, fed, ubt, deb, mint, sles, suse, arch, parabola, nixos, ad ⧝
    def bsd?     ; freebsd? || netbsd? || openbsd?    end 
      def freebsd? ; RUBY_PLATFORM =~ /freebsd/i        end
      def netbsd?  ; RUBY_PLATFORM =~ /netbsd/i         end
      def openbsd? ; RUBY_PLATFORM =~ /openbsd/i        end
    def solaris? ; RUBY_PLATFORM =~ /solaris/i        end

  # TODO: cleanly chain signal handlers to prevent leaving -(echo|icanon) 

  # --- Lé code

  def ask_for_password_on_unix(prompt = "Enter password: ")
    raise 'Could not ask for password because there is no interactive terminal (tty)' unless $stdin.tty?
    unless prompt.nil?
      $stderr.print prompt 
      $stderr.flush
    end
    raise 'Could not disable echo to ask for password security' unless system 'stty -echo -icanon'
    password = $stdin.gets
    password.chomp! if password
    password
  ensure
    raise 'Could not re-enable echo while securely asking for password' unless system 'stty echo icanon'
  end

  def ask_for_password_on_windows(prompt = "Enter password: ")
    raise 'Could not ask for password because there is no interactive terminal (tty)' unless $stdin.tty?

    require 'Win32API'

    char = nil
    password = ''

    unless prompt.nil?
      $stderr.print prompt 
      $stderr.flush
    end

    while char = Win32API.new("crtdll", "_getch", [ ], "L").Call do
      break if char == 10 || char == 13 # return or newline
      if char == 127 || char == 8 # backspace and delete
        password[-1] = ' '
        password.slice!(-1, 1)
      else
        password << char.chr
      end
    end
    char = ' '

    $stderr.puts
    password
  end

  def ask_for_password_on_jruby(prompt = "Enter password: ")
    raise 'Could not ask for password because there is no interactive terminal (tty)' unless $stdin.tty?

    password=''

    require 'java'
    include_class 'java.lang.System'
    include_class 'java.io.Console'

    unless prompt.nil?
      $stderr.print prompt 
      $stderr.flush  
    end

    console = System.console()
    return unless console != java.null
    loop do
      break unless (read_passwd = console.readPassword()) != java.null
      passwd_chr = java.lang.String.new(read_passwd).to_string
      case passwd_chr
        when "\e" # ESC
          password.length.times do |i|
            password[i] = ' '
          end
          return nil
        when "", "\r", "\n" # Enter (for certain), ..., ...
          break
        when "\177", "\b" # Ctrl-H, Bkspace
          if password.length > 0       
            password[-1] = ' '
            password.slice!(-1, 1)
          end
        when "\004" # Ctrl-D
          password.length.times do |i|
            password[i] = ' '
          end
          password = ''
        else
          password << passwd_chr
      end
    end

    $stderr.puts
    passwd
  end

  def ask(prompt = "Enter password: ")
    %w|windows unix jruby|.each do |platform|
      eval "return ask_for_password_on_#{platform}(prompt) if #{platform}?"
    end
    raise "Could not read password on unknown Ruby platform: #{RUBY_DESCRIPTION}"
  end
  extend self
end