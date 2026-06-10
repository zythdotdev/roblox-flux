local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage.Packages.TestEZ)

TestEZ.TestBootstrap:run({
	ReplicatedStorage.Tests.Client["Anima.spec"],
})