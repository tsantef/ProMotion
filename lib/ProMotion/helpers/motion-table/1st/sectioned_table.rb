module ProMotion::MotionTable
  module SectionedTable
    # @param [Array] Array of table data
    # @returns [UITableView] delegated to self
    def createTableViewFromData(data)
      setTableViewData data
      return tableView
    end

    def updateTableViewData(data)
      setTableViewData data
      self.tableView.reloadData
    end

    def setTableViewData(data)
      @mt_table_view_groups = data
    end

    def numberOfSectionsInTableView(tableView)
      if @mt_filtered
        return @mt_filtered_data.length if @mt_filtered_data
      else
        return @mt_table_view_groups.length if @mt_table_view_groups
      end
      0
    end

    # Number of cells
    def tableView(tableView, numberOfRowsInSection:section)
      return sectionAtIndex(section)[:cells].length if sectionAtIndex(section) && sectionAtIndex(section)[:cells]
      0
    end

    def tableView(tableView, titleForHeaderInSection:section)
      return sectionAtIndex(section)[:title] if sectionAtIndex(section) && sectionAtIndex(section)[:title]
    end

    # Set table_data_index if you want the right hand index column (jumplist)
    def sectionIndexTitlesForTableView(tableView)
      self.table_data_index if self.respond_to?(:table_data_index)
    end

    def tableView(tableView, cellForRowAtIndexPath:indexPath)
      # Aah, magic happens here...

      dataCell = cellAtSectionAndIndex(indexPath.section, indexPath.row)
      return UITableViewCell.alloc.init unless dataCell
      dataCell[:cellStyle] ||= UITableViewCellStyleDefault
      dataCell[:cellIdentifier] ||= "Cell"
      cellIdentifier = dataCell[:cellIdentifier]
      dataCell[:cellClass] ||= UITableViewCell

      tableCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
      unless tableCell
        tableCell = dataCell[:cellClass].alloc.initWithStyle(dataCell[:cellStyle], reuseIdentifier:cellIdentifier)
        
        # Add optimizations here
        tableCell.layer.masksToBounds = true if dataCell[:masksToBounds]
        tableCell.backgroundColor = dataCell[:backgroundColor] if dataCell[:backgroundColor]
      end

      if dataCell[:cellClassAttributes]
        set_cell_attributes tableCell, dataCell[:cellClassAttributes]
      end

      tableCell.accessoryView = dataCell[:accessoryView] if dataCell[:accessoryView]
  
      if dataCell[:accessory] && dataCell[:accessory] == :switch
        switchView = UISwitch.alloc.initWithFrame(CGRectZero)
        switchView.addTarget(self, action: "accessoryToggledSwitch:", forControlEvents:UIControlEventValueChanged);
        switchView.on = true if dataCell[:accessoryDefault]
        tableCell.accessoryView = switchView
      end

      if dataCell[:subtitle]
        tableCell.detailTextLabel.text = dataCell[:subtitle]
      end

      tableCell.selectionStyle = UITableViewCellSelectionStyleNone if dataCell[:no_select]

      if dataCell[:image]
        tableCell.imageView.layer.masksToBounds = true
        tableCell.imageView.image = dataCell[:image][:image]
        tableCell.imageView.layer.cornerRadius = dataCell[:image][:radius] if dataCell[:image][:radius]
      end

      # Quite ingenious ;)
      if dataCell[:subViews]
        dataCell[:subViews].each do |view|
          tableCell.subviews.each do  |v|
            if  v == view
              v.removeFromSuperview
            end
          end
          tableCell.addSubview view 
        end
      end

      if dataCell[:details]
        tableCell.addSubview dataCell[:details][:image]
      end

      if dataCell[:styles] && dataCell[:styles][:textLabel] && dataCell[:styles][:textLabel][:frame]
        ui_label = false
        tableCell.contentView.subviews.each do |view|
          if view.is_a? UILabel
            ui_label = true
            view.text = dataCell[:styles][:textLabel][:text]
          end
        end

        unless ui_label == true
          label ||= UILabel.alloc.initWithFrame(CGRectZero)
          set_cell_attributes label, dataCell[:styles][:textLabel]
          tableCell.contentView.addSubview label
        end
        # hackery
        tableCell.textLabel.textColor = UIColor.clearColor
      else
        cell_title = dataCell[:title]
        cell_title ||= ""
        tableCell.textLabel.text = cell_title
      end

      return tableCell
    end

    def sectionAtIndex(index)
      if @mt_filtered
        @mt_filtered_data.at(index)
      else
        @mt_table_view_groups.at(index)
      end
    end

    def cellAtSectionAndIndex(section, index)
      return sectionAtIndex(section)[:cells].at(index) if sectionAtIndex(section) && sectionAtIndex(section)[:cells]
    end

    def tableView(tableView, didSelectRowAtIndexPath:indexPath)
      cell = cellAtSectionAndIndex(indexPath.section, indexPath.row)
      tableView.deselectRowAtIndexPath(indexPath, animated: true);
      triggerAction(cell[:action], cell[:arguments]) if cell[:action]
    end

    def accessoryToggledSwitch(switch)
      tableCell = switch.superview
      indexPath = tableCell.superview.indexPathForCell(tableCell)

      dataCell = cellAtSectionAndIndex(indexPath.section, indexPath.row)
      dataCell[:arguments] = {} unless dataCell[:arguments]
      dataCell[:arguments][:value] = switch.isOn if dataCell[:arguments].is_a? Hash
      
      triggerAction(dataCell[:accessoryAction], dataCell[:arguments]) if dataCell[:accessoryAction]

    end

    def triggerAction(action, arguments)
      if self.respond_to?(action)
        expectedArguments = self.method(action).arity
        if expectedArguments == 0
          self.send(action)
        elsif expectedArguments == 1 || expectedArguments == -1
          self.send(action, arguments)
        else
          MotionTable::Console.log("MotionTable warning: #{action} expects #{expectedArguments} arguments. Maximum number of required arguments for an action is 1.", withColor: MotionTable::Console::RED_COLOR)
        end
      else
        MotionTable::Console.log(self, actionNotImplemented: action)
      end
    end
  
    def set_cell_attributes(element, args = {})
      args.each do |k, v|
        if v.is_a? Hash
          v.each do
            sub_element = element.send("#{k}")
            set_cell_attributes(sub_element, v)
          end
          # v.each do |k2, v2|
          #   sub_element = element.send("#{k}")
          #   sub_element.send("#{k2}=", v2) if sub_element.respond_to?("#{k2}=")
          # end
        else
          element.send("#{k}=", v) if element.respond_to?("#{k}=")
        end
      end
      element
    end
  end
end