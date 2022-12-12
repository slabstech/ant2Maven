package com.slabstech.buildabot

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class BuildabotApplication

fun main(args: Array<String>) {
	runApplication<BuildabotApplication>(*args)
}
