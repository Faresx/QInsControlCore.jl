abstract type Instrument end

struct GPIBInstr <: Instrument
    name::String
    addr::String
    geninstr::GenericInstrument
end

struct SerialInstr <: Instrument
    name::String
    addr::String
    geninstr::GenericInstrument
end

struct TCPIPInstr <: Instrument
    name::String
    addr::String
    ip::IPv4
    port::Int
    sock::Ref{TCPSocket}
    connected::Ref{Bool}
end

Base.@kwdef struct VirtualInstr <: Instrument
    name::String = "VirtualInstr"
    addr::String = "VirtualAddress"
end

function instrument(name, addr)
    if occursin("GPIB", addr)
        return GPIBInstr(name, addr, GenericInstrument())
    elseif occursin("ASRL", addr)
        return SerialInstr(name, addr, GenericInstrument())
    elseif occursin("TCPIP", addr) && occursin("SOCKET", addr)
        try
            _, ip, portstr, _ = split(addr, "::")
            port = parse(Int, portstr)
            return TCPIPInstr(name, addr, IPv4(ip), port, Ref(TCPSocket()), Ref(false))
        catch e
            @error "address is not valid" execption = e
            return GPIBInstr(name, addr, GenericInstrument())
        end
    elseif name == "VirtualInstr"
        return VirtualInstr()
    else
        return GPIBInstr(name, addr, GenericInstrument())
    end
end

connect!(rm, instr::GPIBInstr) = Instruments.connect!(rm, instr.geninstr, instr.addr)
connect!(rm, instr::SerialInstr) = Instruments.connect!(rm, instr.geninstr, instr.addr)
function connect!(_, instr::TCPIPInstr)
    if !instr.connected[]
        instr.sock[] = Sockets.connect(instr.ip, instr.port)
        instr.connected[] = true
    end
end
connect!(_, ::VirtualInstr) = nothing
connect!(instr::Instrument) = connect!(ResourceManager(), instr)

disconnect!(instr::GPIBInstr) = Instruments.disconnect!(instr.geninstr)
disconnect!(instr::SerialInstr) = Instruments.disconnect!(instr.geninstr)
function disconnect!(instr::TCPIPInstr)
    if instr.connected[]
        close(instr.sock[])
        instr.connected[] = false
    end
end
disconnect!(::VirtualInstr) = nothing

Base.write(instr::GPIBInstr, msg::AbstractString) = Instruments.write(instr.geninstr, msg)
Base.write(instr::SerialInstr, msg::AbstractString) = Instruments.write(instr.geninstr, string(msg, "\n"))
Base.write(instr::TCPIPInstr, msg::AbstractString) = println(instr.sock[], msg)
Base.write(::VirtualInstr, ::AbstractString) = nothing

Base.read(instr::GPIBInstr) = Instruments.read(instr.geninstr)
Base.read(instr::SerialInstr) = Instruments.read(instr.geninstr)
Base.read(instr::TCPIPInstr) = readline(instr.sock[])
Base.read(::VirtualInstr) = "read"

query(instr::GPIBInstr, msg::AbstractString; delay=0) = Instruments.query(instr.geninstr, msg; delay=delay)
query(instr::SerialInstr, msg::AbstractString; delay=0) = Instruments.query(instr.geninstr, string(msg, "\n"); delay=delay)
query(instr::TCPIPInstr, msg::AbstractString; delay=0) = (println(instr.sock[], msg); sleep(delay); readline(instr.sock[]))
query(::VirtualInstr, ::AbstractString; delay=0) = "query"