
resource_manifest_version "44febabe-d386-4d18-afbe-5e627f4af937"

dependencies {
	"mysql-async",
}
server_script '@mysql-async/lib/MySQL.lua'

server_script	"npt-acepermitions.lua"

server_script 	"npt-init.lua"
client_script 	"npt-init.lua"

server_script 	"npt-shared.lua"
client_script 	"npt-shared.lua"

server_script	"npt-logs.lua"

server_script	"npt-math.lua"
client_script	"npt-math.lua"

server_script	"npt-sql.lua"

server_script 	"npt-tasker.lua"
client_script 	"npt-tasker.lua"

server_script	"npt-colors.lua"
client_script	"npt-colors.lua"

server_script 	"npt-server.lua"

server_script 	"npt-createped_server.lua"
client_script 	"npt-createped_client.lua"

client_script 	"npt-worldmarkers.lua"

client_script 	"npt-text.lua"

server_script 	"npt-regions_server.lua"
client_script	"npt-regions_client.lua"
client_script	"npt-regions_default.lua"

client_script	"npt-fpsdeviation.lua"
client_script	"npt-blips.lua"

client_script	"npt-runcode.lua"
client_script	"npt-debug.lua"
client_script	"npt-tests.lua"