return {
    debug = true,
    target_rate_kbps = 100000,
    orchestrator = {
        url = "$orch_url",
        user = "$orch_user",
        pass = "$orch_pass",
        workflow = "$orch_workflow",
    },
    node = {
        url = "$node_url",
        user = "$node_user",
        pass = "$node_pass",
    },
}
