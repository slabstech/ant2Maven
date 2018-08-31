#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'

script="./scripts/ant2Maven"


@test "Execute test_mock" {
    assert_equal $(echo 1+1 | bc) 2
    run $script "test" test_mock

    assert_line "Calling this Function"
}

@test "Test get_version_id" {
    json_data=$(cat test/mock_data/json_data.txt)
    run $script "test" get_version_id `echo $json_data`

  #  assert_line "\"response\":{\"numFound\":1,\"start\":0,\"docs\":[{"id":"junit:junit:4.12","g":"junit","a":"junit","v":"4.12","p":"jar","timestamp":1417709863000,"ec":["-sources.jar","-javadoc.jar",".jar",".pom"],"tags":["unit","gamma","created","kent","testing","java","beck","junit","framework","erich"]}]}}"
}

@test "Test jar_modification" {
    json_data=$(cat test/mock_data/json_data.txt)
    run $script "test" jar_modification `echo $json_data`

  #  assert_line "\"response\":{\"numFound\":1,\"start\":0,\"docs\":[{"id":"junit:junit:4.12","g":"junit","a":"junit","v":"4.12","p":"jar","timestamp":1417709863000,"ec":["-sources.jar","-javadoc.jar",".jar",".pom"],"tags":["unit","gamma","created","kent","testing","java","beck","junit","framework","erich"]}]}}"
}

@test "Test get_group_id" {
    json_data=$(cat test/mock_data/json_data.txt)
    run $script "test" get_group_id `echo $json_data`

  #  assert_line "\"response\":{\"numFound\":1,\"start\":0,\"docs\":[{"id":"junit:junit:4.12","g":"junit","a":"junit","v":"4.12","p":"jar","timestamp":1417709863000,"ec":["-sources.jar","-javadoc.jar",".jar",".pom"],"tags":["unit","gamma","created","kent","testing","java","beck","junit","framework","erich"]}]}}"
}

@test "Test get_artifact_id" {
    json_data=$(cat test/mock_data/json_data.txt)
    run $script "test" get_artifact_id `echo $json_data`

  #  assert_line "\"response\":{\"numFound\":1,\"start\":0,\"docs\":[{"id":"junit:junit:4.12","g":"junit","a":"junit","v":"4.12","p":"jar","timestamp":1417709863000,"ec":["-sources.jar","-javadoc.jar",".jar",".pom"],"tags":["unit","gamma","created","kent","testing","java","beck","junit","framework","erich"]}]}}"
}

@test "Test generate_lib_removal" {
    json_data=$(cat test/mock_data/json_data.txt)
    run $script "test" generate_lib_removal `echo $json_data`

  #  assert_line "\"response\":{\"numFound\":1,\"start\":0,\"docs\":[{"id":"junit:junit:4.12","g":"junit","a":"junit","v":"4.12","p":"jar","timestamp":1417709863000,"ec":["-sources.jar","-javadoc.jar",".jar",".pom"],"tags":["unit","gamma","created","kent","testing","java","beck","junit","framework","erich"]}]}}"
}



@test "Test populate_metadata" {

    run $script "test" populate_metadata
  #  assert_success
    #assert_line "\"response\":{\"numFound\":1,\"start\":0,\"docs\":[{"id":"junit:junit:4.12","g":"junit","a":"junit","v":"4.12","p":"jar","timestamp":1417709863000,"ec":["-sources.jar","-javadoc.jar",".jar",".pom"],"tags":["unit","gamma","created","kent","testing","java","beck","junit","framework","erich"]}]}}"
}



@test "Validate ignore_jars function" {

    echo -e "example/lib/junit-4.12.jar 	 junit-4.12.jar	 4.12 	 4.12 	 1 	 0  	 junit 	 junit" >> library_metadata.txt
    echo -e "example/lib/apache-mime4j-0.6.jar 	 apache-mime4j-0.6.jar	 0.6 	 0.8.2 	 1 	 0  	 org.apache.james 	 apache-mime4j" >> library_metadata.txt
    run $script "test" process_ignore_list
  #  assert_success
    #TODO assert the line removed
    #tmp=`cat library_metadata.txt`
    #assert_line "Calling this Function" $tmp

}
