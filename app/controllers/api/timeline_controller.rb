class Api::TimelineController < ApiController
  def new
    _post = params[:timeline]
    status = Hash.new
    if _post['year'] && _post['half'] && _post['tcc']
      base = BaseTimeline.find_by year: _post['year'], half: _post['half'], tcc: _post['tcc']
      timeline = {
          student_id: _post['student'],
          teacher_id: _post['teacher'],
          base_timeline_id: base ? base.id : nil
      }
      t = Timeline.new timeline
      if t.save
        t.createItems
        status[:success] = true
      else
        status = t.errors
      end
    else
      status[:errors] = [['Especifique ano, semestre e TCC.']]
    end

    render :inline => status.to_json
  end

  def find
    base = BaseTimeline.find_by :year => params[:year], :half => params[:half], :tcc => params[:tcc]
    status = Hash.new
    if base
      _timelines = Timeline.where :base_timeline_id => base.id
      timelines = Array.new
      _timelines.each do |timeline|
        timelines.push timeline.serialize
      end
      status[:timelines] = timelines
    else
      status[:errors] = [['Nenhum TCC encontrado.']]
    end
    render :inline => status.to_json
  end

  def getItem
    status = Hash.new
    begin
      item = ItemTimeline.find params[:id]
      status = item.attributes
      status[:base] = item.item_base_timeline.attributes
    rescue ActiveRecord::RecordNotFound => e
      status[:errors] = [['Item de entrega não encontrado.']]
    rescue Exception => e
      status[:errors] = [[e.message]]
    end
    render :inline => status.to_json
  end

  def sendFile
    status = Hash.new
    begin
      item = ItemTimeline.find params[:id]
      if params[:file].content_type != 'image/jpeg' && params[:file].content_type != 'application/pdf'
        raise 'Formato não suportado.'
      end
      name = params[:id].to_s+"-"+params[:file].original_filename
      directory = "public/uploads"
      path = File.join(directory, name)
      File.open(path, "wb") { |f| f.write(params['file'].read) }
      item.file = directory+'/'+name
      item.status = 'pending'
      item.save
      # notify teacher and save log
      status[:success] = true
    rescue Exception => e
      status[:errors] = [[e.message]]
    end
    render :inline => status.to_json
  end
end
