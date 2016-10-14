require 'gen'
require 'torch'
require 'nn'
require 'rnn'

cmd = torch.CmdLine()
cmd:option('-o', '', 'Output file name')
cmd:option('-model', '', 'Model file name')
cmd:option('-temperature', 1.0, 'Temperature')
cmd:option('-firstnote', 41, 'First note index 1-88')
cmd:option('-len', 100, 'Length of the notes')
opt = cmd:parse(arg or {})

--TODO test
function create_song()
	local song = torch.Tensor(opt.len, data_width)
	local x = torch.zeros(rho, data_width)
	x[rho][opt.firstnote] = 1
	local frame = torch.zeros(data_width)
	for i=1, opt.len do
		for u=2, rho do
			x[u-1] = x[u]
		end
		x[rho] = frame

		local pd = model:forward(x)--Probability distribution... thing
		pd = pd:reshape(data_width)
		frame = sample(pd)

		song[i] = frame
	end
	print("Done")

	if opt.o ~= '' then 
		generate(torch.totable(song), opt.o)
	else print(get_notes(song)) end
end

--Kind of... empty arrays
--Gotta fix the model or this function FIXME
function sample(r)
	r = torch.exp(torch.log(r) / opt.temperature)
	r = r / torch.sum(r)
	local k = 1.5
	r = r*(k / torch.sum(r)) --Make the sum of r = k

	local frame = torch.zeros(data_width)
	for i = 1, data_width do
		local rand = math.random()
		if r[i] > rand then frame[i] = 1 end
	end
	return frame
end

function get_notes(r)
	local notes = {}
	for i=1, opt.len  do
		notes[i] = {}
		for u=1, data_width do
			if r[i][u] ~= 0 then
				notes[i][#notes[i]+1] = u
			end
		end
	end
	return notes
end

model = torch.load(opt.model)
data_width = model:get(1).inputSize
rho = model:get(1).rho
create_song()
