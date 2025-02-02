using DataStructures
using Base.Order
using ResumableFunctions
import Base.length

mutable struct HierarchicalSoftmaxNode
	parent::Int32
	branch::Bool
end

struct HierarchicalOutput
	code::Array{Int8}
	path::Array{Int}
end


length(out::HierarchicalOutput) = length(out.path)

function HierarchicalSoftmaxNode()
	return HierarchicalSoftmaxNode(Int32(0), false)
end

@resumable function softmax_path(nodes::Array{HierarchicalSoftmaxNode},
		V::Integer, id::Integer) :: Tuple{Int32, Int8}
	while true
		node = nodes[id]
		if node.parent == 0 break; end
		@assert node.parent > V
		@yield (Int32(node.parent - V), Int8(node.branch))
		id = node.parent
	end
end

function build_huffman_tree(freqs::Array{Tf}) where {Tf <: Number}
	V = length(freqs)
	nodes = Array{HierarchicalSoftmaxNode}(undef, V)
	for v in 1:V
		nodes[v] = HierarchicalSoftmaxNode()
	end

	freq_ord = By(wf -> wf[2])
	heap = heapify!([(nodes[v], freqs[v]) for v in 1:V], freq_ord)

	function pop_initialize!(parent::Int, branch::Bool)
		node = heappop!(heap, freq_ord)
		node[1].parent = Int32(parent)
		node[1].branch = branch
		return node[2]
	end

	L = V
	while length(heap) > 1
		L += 1
		node = HierarchicalSoftmaxNode()
		push!(nodes, node)

		freq = 1
		freq = pop_initialize!(L, true) + pop_initialize!(L, false)
		heappush!(heap, (node, freq), freq_ord)
	end

	@assert(length(heap) == 1, string(heap))

	return nodes
end

function convert_huffman_tree(nodes::Array{HierarchicalSoftmaxNode}, V::Integer)
	outputs = Array{HierarchicalOutput, 1}(undef, V)
	for v in 1:V
		code = Array{Int8, 1}()
		path = Array{Int, 1}()

		for (n, branch) in softmax_path(nodes, V, v)
			push!(code, branch)
			push!(path, n)
		end

		outputs[v] = HierarchicalOutput(code, path)
	end

	return outputs
end

export HierarchicalSoftmaxNode, softmax_path
