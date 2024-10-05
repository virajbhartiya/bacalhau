#!bin/bashtub

source bin/bacalhau.sh

testcase_can_follow_job_logs() {
    create_node orchestrator,compute

    subject ${BACALHAU} job run --follow $ROOT/testdata/jobs/wasm.yaml
    assert_equal 0 $status
    assert_match 'Hello, world!' $(echo $stdout | tail -n1)
    assert_equal '' $stderr
}
