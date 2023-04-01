module QInsControlCore
    using Instruments
    using Sockets
    using UUIDs

    export Controller, Processor
    export login!, logout!, start!, stop!, isready, getdata!, reconnect!

    include("Instruments.jl")
    include("DataStream.jl")
end # module QInsControlCore
