require 'midiparse'
require 'lfs'
require 'rnn'
require 'optim'

require 'cltorch'
require 'clnn'

function validate(model, rho, batchsize,dir, criterion)
	local valid_data = create_data(dir) --Faster than saving

	local toterr = 0
	local c = 0
	local bs = 1

	local x = torch.Tensor(batchsize, rho, 93)
	local y = torch.Tensor(batchsize, 93)

	for _, song in pairs(valid_data) do
		for i=1, #song-rho-2 do

			for o=1, rho do
				x[bs][o] = torch.Tensor(song[i+o-1])
			end
			y[bs] = torch.Tensor(song[i+rho])
			bs = bs+1

			if bs == batchsize then
				local yhat = 0
				local err = nil
				if opt.opencl then
					yhat = model:forward(x:cl())
					err =  torch.mean(torch.abs(y:cl() - yhat))
				else
					yhat = model:forward(x)
					err = torch.mean(torch.abs(y - yhat))
				end
				toterr = toterr + err
				x = torch.Tensor(batchsize, rho, 93)
				y = torch.Tensor(batchsize, 93)
				c = c+1
				bs = 1
			end
			
		end
	end

	collectgarbage()

	return toterr / c
end

function normalize(r, col)
	for i=1, #r do
		for u=1, #r[i] do
			if r[i][u][col] > 4000 then r[i][u][col] = 4000 end
			r[i][u][col] = math.log(r[i][u][col]+1) / 8.294
		end
	end
	return r
end

function create_data(dir)
	local songs = {}
	for filename in lfs.dir(dir.."/.") do
		if filename[1] == '.' then goto cont end
		local song = parse(dir.."/"..filename) 
		songs[#songs+1] = song
		::cont::
	end
	songs = normalize(songs, 92)
	songs = normalize(songs, 93)
	return songs
end
