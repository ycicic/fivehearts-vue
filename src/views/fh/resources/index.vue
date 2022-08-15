<template>
  <div class="app-container">
    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch" label-width="68px">
      <el-form-item label="资源类型" prop="type">
        <el-select v-model="queryParams.type" placeholder="请选择资源类型" clearable>
          <el-option
              v-for="dict in fh_resources_type"
              :key="dict.value"
              :label="dict.label"
              :value="dict.value"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="名称" prop="name">
        <el-input
            v-model="queryParams.name"
            placeholder="请输入名称"
            clearable
            @keyup.enter="handleQuery"
        />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button
            type="primary"
            plain
            icon="Plus"
            @click="handleAdd"
            v-hasPermi="['fh:resources:add']"
        >新增
        </el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button
            type="success"
            plain
            icon="Edit"
            :disabled="single"
            @click="handleUpdate"
            v-hasPermi="['fh:resources:edit']"
        >修改
        </el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button
            type="danger"
            plain
            icon="Delete"
            :disabled="multiple"
            @click="handleDelete"
            v-hasPermi="['fh:resources:remove']"
        >删除
        </el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button
            type="warning"
            plain
            icon="Download"
            @click="handleExport"
            v-hasPermi="['fh:resources:export']"
        >导出
        </el-button>
      </el-col>
      <right-toolbar v-model:showSearch="showSearch" @queryTable="getList"></right-toolbar>
    </el-row>

    <el-table v-loading="loading" :data="resourcesList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" align="center"/>
      <el-table-column label="主键ID" align="center" prop="id"/>
      <el-table-column label="资源类型" align="center" prop="type">
        <template #default="scope">
          <dict-tag :options="fh_resources_type" :value="scope.row.type"/>
        </template>
      </el-table-column>
      <el-table-column label="名称" align="center" prop="name"/>
      <el-table-column label="资源详情" align="center">
        <template #default="scope">
          <div v-if="scope.row.type === 1">
            <image-preview :src="scope.row.info" style="max-height: 6rem;"/>
          </div>
          <div v-else>
            <span>{{ scope.row.info }}</span>
          </div>
        </template>
      </el-table-column>
      <el-table-column label="备注" align="center" prop="remark"/>
      <el-table-column label="更新时间" align="center" prop="updateTime" width="180">
        <template #default="scope">
          <span>{{ parseTime(scope.row.updateTime) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="操作" align="center" class-name="small-padding fixed-width">
        <template #default="scope">
          <el-button
              type="text"
              icon="Edit"
              @click="handleUpdate(scope.row)"
              v-hasPermi="['fh:resources:edit']"
          >修改
          </el-button>
          <el-button
              type="text"
              icon="Delete"
              @click="handleDelete(scope.row)"
              v-hasPermi="['fh:resources:remove']"
          >删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination
        v-show="total>0"
        :total="total"
        v-model:page="queryParams.current"
        v-model:limit="queryParams.size"
        @pagination="getList"
    />

    <!-- 添加或修改资源管理对话框 -->
    <el-dialog :title="title" v-model="open" width="500px" append-to-body>
      <el-form ref="resourcesRef" :model="form" :rules="rules" label-width="80px">
        <el-form-item label="资源类型" prop="type">
          <el-select v-model="form.type" placeholder="请选择资源类型">
            <el-option
                v-for="dict in fh_resources_type"
                :key="dict.value"
                :label="dict.label"
                :value="parseInt(dict.value)"
            ></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="名称" prop="name">
          <el-input v-model="form.name" placeholder="请输入名称"/>
        </el-form-item>
        <el-form-item label="资源详情" prop="info">
          <image-upload v-if="form.type === 1" v-model="form.info" :fileSize="50"/>
          <el-input v-else v-model="form.info" type="textarea" placeholder="请输入内容"/>
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="form.remark" type="textarea" placeholder="请输入内容"/>
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button type="primary" @click="submitForm">确 定</el-button>
          <el-button @click="cancel">取 消</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup name="Resources">
import {listResources, getResources, delResources, addResources, updateResources} from "@/api/fh/resources";

const {proxy} = getCurrentInstance();
const {fh_resources_type} = proxy.useDict('fh_resources_type');

const resourcesList = ref([]);
const imageList = ref([]);
const open = ref(false);
const loading = ref(true);
const showSearch = ref(true);
const ids = ref([]);
const single = ref(true);
const multiple = ref(true);
const total = ref(0);
const title = ref("");

const data = reactive({
  form: {},
  queryParams: {
    current: 1,
    size: 10,
    type: null,
    name: null,
  },
  rules: {
    type: [
      {required: true, message: "资源类型不能为空", trigger: "change"}
    ],
  }
});

const {queryParams, form, rules} = toRefs(data);

/** 查询资源管理列表 */
function getList() {
  loading.value = true;
  listResources(queryParams.value).then(response => {
    resourcesList.value = response.data.records;
    let srcList = [];
    response.data.records.forEach((d) => {
      if (d.type === 1) {
        let real_src_list = d.info.split(",");
        real_src_list.forEach((src) => srcList.push(src));
      }
    });
    imageList.value = srcList;
    total.value = response.data.total;
    loading.value = false;
  });
}

// 取消按钮
function cancel() {
  open.value = false;
  reset();
}

// 表单重置
function reset() {
  form.value = {
    id: null,
    type: null,
    name: null,
    info: null,
    createBy: null,
    createTime: null,
    updateBy: null,
    updateTime: null,
    deleted: null,
    remark: null
  };
  proxy.resetForm("resourcesRef");
}

/** 搜索按钮操作 */
function handleQuery() {
  queryParams.value.current = 1;
  getList();
}

/** 重置按钮操作 */
function resetQuery() {
  proxy.resetForm("queryRef");
  handleQuery();
}

// 多选框选中数据
function handleSelectionChange(selection) {
  ids.value = selection.map(item => item.id);
  single.value = selection.length != 1;
  multiple.value = !selection.length;
}

/** 新增按钮操作 */
function handleAdd() {
  reset();
  open.value = true;
  title.value = "添加资源管理";
}

/** 修改按钮操作 */
function handleUpdate(row) {
  reset();
  const id = row.id || ids.value
  getResources(id).then(response => {
    form.value = response.data;
    open.value = true;
    title.value = "修改资源管理";
  });
}

/** 提交按钮 */
function submitForm() {
  proxy.$refs["resourcesRef"].validate(valid => {
    if (valid) {
      if (form.value.id != null) {
        updateResources(form.value).then(response => {
          proxy.$modal.msgSuccess("修改成功");
          open.value = false;
          getList();
        });
      } else {
        addResources(form.value).then(response => {
          proxy.$modal.msgSuccess("新增成功");
          open.value = false;
          getList();
        });
      }
    }
  });
}

/** 删除按钮操作 */
function handleDelete(row) {
  const ids = row.id || ids.value;
  proxy.$modal.confirm('是否确认删除资源管理编号为"' + ids + '"的数据项？').then(function () {
    return delResources(ids);
  }).then(() => {
    getList();
    proxy.$modal.msgSuccess("删除成功");
  }).catch(() => {
  });
}

/** 导出按钮操作 */
function handleExport() {
  proxy.download('fh/resources/export', {
    ...queryParams.value
  }, `resources_${new Date().getTime()}.xlsx`)
}

getList();
</script>
