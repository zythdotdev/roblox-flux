local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage.Packages.TestEZ)

TestEZ.TestBootstrap:run({
	ReplicatedStorage.Tests.Client["State.spec"],
	ReplicatedStorage.Tests.Client["Controller.spec"],
	ReplicatedStorage.Tests.Client["Component.spec"],
})