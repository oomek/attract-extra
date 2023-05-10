/*
################################################################################

Attract-Mode Frontend - PowerOptions Plugin v1.01

by Oomek - Radek Dutkiewicz 2023
https://github.com/oomek/attract-extra

################################################################################
*/

class UserConfig </ help="Power Options v1.01" /> {}

class PowerOptions
{
	static VERSION = 1.01
	commands = null

	constructor()
	{
		switch ( OS )
		{
			case "Windows":
				commands =
				{
					reboot   = { cmd = "shutdown", param = @"/r /t 0" },
					poweroff = { cmd = "shutdown", param = @"/s /t 0" },
					suspend  = { cmd = "rundll32.exe", param = "powrprof.dll, SetSuspendState 0,1,0" },
				}
				break

			case "OSX":
				commands =
				{
					reboot   = { cmd = "osascript", param = "-e 'tell app \"System Events\" to restart'" },
					poweroff = { cmd = "osascript", param = "-e 'tell app \"System Events\" to shut down'" },
					suspend  = { cmd = "osascript", param = "-e 'tell app \"System Events\" to sleep'" },
				}
				break

			case "FreeBSD":
			case "Linux":
				commands =
				{
					reboot   = { cmd = "systemctl", param = "reboot"},
					poweroff = { cmd = "systemctl", param = "poweroff"},
					suspend  = { cmd = "systemctl", param = "suspend"},
				}
				break

			case "Unknown":
			default:
				commands =
				{
					reboot   = { cmd = "", param = ""},
					poweroff = { cmd = "", param = ""},
					suspend  = { cmd = "", param = ""},
				}
		}

		fe.add_signal_handler( this, "power_options_on_signal" )
	}

	function show_dialog()
	{
		local dialog_title = "POWER OPTIONS"

		local dialog_options = []
		dialog_options.push( "Exit Attract-Mode" )
		dialog_options.push( "Reboot" )
		dialog_options.push( "Power Off" )
		dialog_options.push( "Suspend" )
		dialog_options.push( "Back" )

		local result = fe.overlay.list_dialog( dialog_options, dialog_title )

		switch( result )
		{
			case 0:
				fe.signal( "exit_to_desktop" )
				break

			case 1:
				fe.plugin_command_bg( commands.reboot.cmd, commands.reboot.param )
				break

			case 2:
				fe.plugin_command_bg( commands.poweroff.cmd, commands.poweroff.param )
				break

			case 3:
				fe.plugin_command_bg( commands.suspend.cmd, commands.suspend.param )
				break

			default:
				break
		}
	}

	function power_options_on_signal( sig )
	{
		switch ( sig )
		{
			case "exit":
				if ( ScreenSaverActive ) return false
				show_dialog()
				return true

			default:
				return false
		}
	}
}

fe.plugin[ "PowerOptions" ] <- PowerOptions()
