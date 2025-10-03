extends Node

signal LogMessage(msg:String)

func Log(...what):
	var msg := " ".join(what.map(str))
	print(msg)
	LogMessage.emit(msg)
