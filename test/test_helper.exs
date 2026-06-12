Application.put_env(:nbp_req, :req_options, plug: {Req.Test, NbpReq})

ExUnit.start()
