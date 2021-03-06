classdef TriPlotSamples < handle
	
	properties (Access = private)
		COLS
		ROWS
		ND
		ax
		borderSize
		figSize
		%subplotSize % dependent?
		PRIOR
		POSTERIOR
		priorCol
		posteriorCol
		labels
		trueVals
		plotHDI
		pointEstimateType
	end
	
	properties (Dependent)
		subplotSize
	end
	
	methods
		
		function obj = TriPlotSamples(POSTERIOR, labels, varargin)
			p = inputParser;
			p.FunctionName = mfilename;
			p.addRequired('POSTERIOR',@ismatrix);
			p.addRequired('labels',@iscellstr);
			p.addParameter('PRIOR',[],@ismatrix);
			p.addParameter('trueVals',[],@isvector);
			p.addParameter('posteriorCol',[0.2 0.2 0.2],@isvector);
			p.addParameter('priorCol',[0.8 0.8 0.8],@isvector);
			p.addParameter('figSize',22,@isscalar);
			p.addParameter('plotHDI',true,@islogical);
			p.addParameter('pointEstimateType','mode', @(x)any(strcmp(x,{'mean','median','mode'})));
			p.parse(POSTERIOR, labels, varargin{:});
			
			% add p.Results fields into obj
			fields = fieldnames(p.Results);
			for n=1:numel(fields)
				obj.(fields{n}) = p.Results.(fields{n});
			end
			
			[~, ND] = size(POSTERIOR);
			obj.ROWS = ND;
			obj.COLS = ND;
			obj.ND = ND;
			obj.POSTERIOR = POSTERIOR;
			obj.borderSize = 2;
			
			% core business
			obj.plot()
			obj.addLabels()
			obj.removeAxisTickLabels()
			obj.subplotPositioning()
			
			set(gcf,...
				'Units', 'centimeters',...
				'Position',[1 1 obj.figSize obj.figSize])
			drawnow
		end
		
		
		function value = get.subplotSize(obj)
			value = (obj.figSize-(2*obj.borderSize))/obj.ND;
		end
		
		
		function plot(obj)
			
			% TODO: add axis_target input variable, to plot to a specific axis
			
			univar_plot_func = @(row,col) ...
				mcmc.UnivariateDistribution(obj.POSTERIOR(:,col),...
				'killYAxis', true,...
				'pointEstimateType',obj.pointEstimateType,...
				'FaceAlpha',1,...
				'plotStyle', 'hist');
			
			bivar_plot_func = @(row,col) ...
				mcmc.BivariateDistribution(...
				obj.POSTERIOR(:,col),...
				obj.POSTERIOR(:,row),...
				'pointEstimateType',obj.pointEstimateType,...
				'plotStyle', 'scatter');
			
			% univariate plot on the diagnonal
			for n = 1:obj.ND
				obj.ax(n,n) = subplot(obj.ROWS, obj.COLS, sub2ind([obj.COLS obj.ROWS], n, n) );
				univar_plot_func(n,n);
			end
			
			% bivariate plot on lower triangle
			for col = 1:obj.ND-1
				for row = col+1:obj.ND
					obj.ax(row,col) = subplot(obj.ROWS, obj.COLS, sub2ind([obj.COLS obj.ROWS], col, row) );
					bivar_plot_func(row,col);
				end
			end

		end

	end
	
	methods (Access = private)
		
		function addLabels(obj)
			for row = 1:obj.ND
				for col = 1:obj.ND
					
					if col>row, break, end
					
					subplot(obj.ROWS, obj.COLS, sub2ind([obj.COLS obj.ROWS], col, row) )
					if obj.shouldAddYLabel(row,col)
						ylabel( obj.labels{row} , 'Interpreter', 'latex')
					end
					
					if obj.shouldAddXLabel(row, col)
						xlabel( obj.labels{col} , 'Interpreter', 'latex')
					end
					
				end
			end
		end
		
		
		function removeAxisTickLabels(obj)
			for row = 1:obj.ND
				for col = 1:obj.ND
					
					if col>row, break, end
					
					% remove x ticks on all but bottom row
					if row~=obj.ND
						set(obj.ax(row,col),'XTickLabels',[]);
					end
					
					% remove y ticks on all but 1st column
					if obj.shouldRemoveYTicks(row,col)
						set(obj.ax(row,col),'YTickLabels',[]);
					end
				end
			end
		end
		
		function subplotPositioning(obj)
			for row = 1:obj.ND
				for col = 1:obj.ND
					if col>obj.ND+1-row, break, end % TODO: simplify conditional, or replace with method
					% 					% absolute positioning
					% 					set(obj.ax(obj.ND+1-row,col),...
					% 						'Position', obj.calcPositionVectorAbsolute(row,col),...
					% 						'Units','centimeters')
					% normalised
					set(obj.ax(obj.ND+1-row,col),...
						'Position', obj.calcPositionVectorNormalised(row,col),...
						'Units','normalized')
				end
			end
		end
		
		function pos = calcPositionVectorNormalised(obj, row, col)
			borderSize = 0.1; % user defined
			actionArea = 1-(2*borderSize);
			subplotSize = actionArea / obj.ND;
			
			left = borderSize + subplotSize*(col-1);
			bottom = borderSize + subplotSize*(row-1);
			width = subplotSize;
			height = subplotSize;
			
			pos = [left, bottom, width, height];
		end
		
		% 		function pos = calcPositionVectorAbsolute(obj, row, col)
		% 			pos = [obj.borderSize + obj.subplotSize*(col-1)...
		% 				obj.borderSize + obj.subplotSize*(row-1)...
		% 				obj.subplotSize...
		% 				obj.subplotSize];
		% 		end
		
		function plotUnivariateTrueValue(obj)
			if ~isempty(obj.trueVals)
				ylims=get(gca,'Ylim');
				line([obj.trueVals(col) obj.trueVals(col)], ylims,...
					'Color','k', 'LineStyle',':');
			end
		end
		
		function plotBivariateTrueValues(obj)
			if numel(obj.trueVals)>0
				ylims=get(gca,'Ylim');
				line([obj.trueVals(col) obj.trueVals(col)], ylims,...
					'Color','k', 'LineStyle',':');
				xlims=get(gca,'Xlim');
				line(xlims, [obj.trueVals(row) obj.trueVals(row)],...
					'Color','k', 'LineStyle',':');
			end
		end
		
		function bool = shouldAddXLabel(obj, row,col)
			bool = row==obj.ND && col<=obj.ND;
		end
		
	end
	
	methods (Static)
		
		function bool = shouldRemoveYTicks(row,col)
			bool = col~=1 || ( col==1 && row==1);
		end
		
		function bool = shouldAddYLabel(row,col)
			bool = col==1 && row>1;
		end
		
	end
	
end
