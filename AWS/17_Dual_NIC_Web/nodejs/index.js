const express = require('express')

const IP1   = process.env.IP1 || '0.0.0.0'
const IP2   = process.env.IP2 || '0.0.0.0'

const PORT1 = process.env.PORT1 || 3001
const PORT2 = process.env.PORT2 || 3002

const app1 = express()
const app2 = express()

app1.get("/", (req, rsp) => { rsp.send("APP1 OK").status(200) } )
app2.get("/", (req, rsp) => { rsp.send("APP1 OK").status(200) } )

app1.listen(PORT1, IP1, () => { console.log(`App1 listening on host ${IP1} port ${PORT1}`) })
app2.listen(PORT2, IP2, () => { console.log(`App1 listening on host ${IP2} port ${PORT2}`) })
