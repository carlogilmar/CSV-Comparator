defmodule Comparator do

  def read(path) do
    {:ok, text} = File.read path #"/Users/carlogilmar/Desktop/comparator.csv"
    text
  end

  def get_rows_from_file( path ) do
    lines = read(path) |> String.split("\r\n")
    for line <- lines do
      rows = String.split(line, ",")
			diablito( Enum.at( rows, 15), rows )
    end
  end

	def diablito("INVERSIÓN FINANCIAMIENTO Y COBERTURA", rows) do
      %{
				type: :magic_file,
        nrc: Enum.at( rows, 16),
        begin: Enum.at( rows, 17),
        end: Enum.at( rows, 18),
        start_time: Enum.at( rows, 19),
        end_time: Enum.at( rows, 20),
        monday: set_nil(Enum.at( rows, 22)),
        tuesday: set_nil(Enum.at( rows, 23)),
        wednesday: set_nil(Enum.at( rows, 24)),
        thursday: set_nil(Enum.at( rows, 25)),
        friday: set_nil(Enum.at( rows, 26)),
        saturday: set_nil(Enum.at( rows, 27)),
        sunday: set_nil(Enum.at( rows, 28))
      }
	end

	def diablito(_, rows) do
      %{
				type: :file,
        nrc: Enum.at( rows, 15),
        begin: Enum.at( rows, 16),
        end: Enum.at( rows, 17),
        start_time: Enum.at( rows, 18),
        end_time: Enum.at( rows, 19),
        monday: set_nil(Enum.at( rows, 21)),
        tuesday: set_nil(Enum.at( rows, 22)),
        wednesday: set_nil(Enum.at( rows, 23)),
        thursday: set_nil(Enum.at( rows, 24)),
        friday: set_nil(Enum.at( rows, 25)),
        saturday: set_nil(Enum.at( rows, 26)),
        sunday: set_nil(Enum.at( rows, 27))
      }
	end

	def set_nil( s ) do
		case s do
			"" -> nil
			_ -> s
		end
	end

	def find_my_assigned_file() do
		prepare_data_for_compare( "http://10.31.22.94:8283/api/coursesBanner/201894", "/Users/carlogilmar/Desktop/comparator.csv")
	end

  def prepare_data_for_compare( broker_url, file_path ) do
    rows = get_rows_from_file( file_path )
		broker_rows = get_broker_info( broker_url )
		for row <- rows do
			compare( row, broker_rows )
		end
  end

	def compare( row, broker ) do
		broker_row = broker |> Enum.find( fn x -> x.nrc == row.nrc and x.begin == row.begin and x.end == row.end end)
		debugger_row( broker_row, row )
		{
			broker_row.nrc == row.nrc,
			broker_row.begin == row.begin,
			broker_row.end == row.end,
			broker_row.start_time == row.start_time,
			broker_row.end_time == row.end_time,
			broker_row.monday == row.monday,
			broker_row.tuesday == row.tuesday,
			broker_row.wednesday == row.wednesday,
			broker_row.thursday == row.thursday,
			broker_row.friday == row.friday,
			broker_row.saturday == row.saturday,
			broker_row.sunday == row.sunday,
		}
	end

	def debugger_row( nil, row ) do
		IO.puts " ::: No se encontró row en el broker::"
		IO.inspect row
	end

	def debugger_row( _, _row ), do: IO.puts "ok"

  def get_broker_info( url ) do
    response = HTTPoison.get! url #"http://10.31.22.94:8283/api/coursesBanner/201894"
    courses = Poison.decode!( response.body )
    for course <- courses do
      %{
				type: :broker,
        nrc: course["nrc"],
        begin: parse_date_from_storage(course["startDate"]),
        end: parse_date_from_storage(course["endDate"]),
        start_time: parse_time(course["beginTime"]),
        end_time: parse_time(course["endTime"]),
        monday: course["monday"],
        tuesday: course["tuesday"],
        wednesday: course["wednesday"],
        thursday: course["thursday"],
        friday: course["friday"],
        saturday: course["saturday"],
        sunday: course["sunday"]
      }
    end
  end

  def parse_time( time ) do
    << h1::8, h2::8, m1::8, m2::8 >> = time
    <<h1>> <> <<h2>> <> ":" <> <<m1>> <> <<m2>>
  end

  def parse_date_from_storage( date ) when byte_size(date) == 21 do
    << y1::8, y2::8, y3::8, y4::8, _::8, m1::8, m2::8, _::8, d1::8, d2::8, _::8*11 >> = date
    <<y1>> <> <<y2>> <> <<y3>> <> <<y4>> <> "-" <> <<m1>> <> <<m2>> <> "-" <> <<d1>> <> <<d2>>
  end
end
